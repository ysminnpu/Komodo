include "kev_constants.dfy"
include "Maybe.dfy"

type PageNr = int
type InsecurePageNr = int

function NR_L1PTES(): int { 256 }
function NR_L2PTES(): int { 1024 }

predicate validPageNr(p: PageNr)
{
    0 <= p < KEVLAR_SECURE_NPAGES()
}

datatype AddrspaceState = InitState | FinalState | StoppedState

datatype PageDbEntryTyped
    = Addrspace(l1ptnr: PageNr, refcount: nat, state: AddrspaceState)
    | Dispatcher(entrypoint:int, entered: bool)
    | L1PTable(l1pt: seq<Maybe<PageNr>>)
    | L2PTable(l2pt: seq<L2PTE>)
    | DataPage

datatype L2PTE
    = SecureMapping(page: PageNr, write: bool, exec: bool)
    | InsecureMapping(insecurePage: InsecurePageNr)
    | NoMapping

datatype PageDbEntry
    = PageDbEntryFree
    | PageDbEntryTyped(addrspace: PageNr, entry: PageDbEntryTyped)

type PageDb = imap<PageNr, PageDbEntry>

predicate wellFormedPageDb(d: PageDb)
{
    forall n :: validPageNr(n) <==> n in d
}

predicate validPageDb(d: PageDb)
{
    wellFormedPageDb(d)
    && pageDbEntriesValidRefs(d)
    && pageDbEntriesValid(d)
}

predicate pageDbEntriesValid(d:PageDb)
    requires wellFormedPageDb(d)
{
    forall n :: n in d ==> validPageDbEntry(d, n)
}

predicate pageDbEntriesValidRefs(d: PageDb)
{
    forall n :: n in d && d[n].PageDbEntryTyped? ==> 
        pageDbEntryValidRefs(d, n)
}

predicate validPageDbEntry(d: PageDb, n: PageNr)
    requires n in d
{
    var e := d[n];
    e.PageDbEntryFree? ||
    (e.PageDbEntryTyped? && validPageDbEntryTyped(d, n))
}

predicate validPageDbEntryTyped(d: PageDb, n: PageNr)
    requires n in d && d[n].PageDbEntryTyped?
{
    var e := d[n].entry;
    (wellFormedPageDbEntry(d, e) || stoppedAddrspace(d, n)) &&
    pageDbEntryWellTypedAddrspace(d, n)
    //|| stoppedAddrspace(d, n)
}

predicate stoppedAddrspace(d: PageDb, n: PageNr)
    requires n in d && d[n].PageDbEntryTyped?
{
    var a := d[n].addrspace;
    a in d && d[a].PageDbEntryTyped? && d[a].entry.Addrspace? &&
        d[a].entry.state == StoppedState
}


// The addrspace of the entry is set correctly. For addrspaces,
// the reference count is correct.
predicate pageDbEntryWellTypedAddrspace(d: PageDb, n: PageNr)
    requires n in d && d[n].PageDbEntryTyped?
{
    var entry := d[n].entry;
    var addrspace := d[n].addrspace;
    addrspace in d
    && d[addrspace].PageDbEntryTyped?
    && d[addrspace].entry.Addrspace?
    // Type-specific requirements
    && ( (entry.Addrspace? && addrspaceOkAddrspace(d, n, addrspace))
       || (entry.L1PTable? && (stoppedAddrspace(d, n) || addrspaceOkL1PTable(d, n, addrspace)))
       || (entry.L2PTable? && (stoppedAddrspace(d, n) || addrspaceOkL2PTable(d, n, addrspace)))
       || (entry.Dispatcher?)
       || (entry.DataPage?) )
    
}

predicate addrspaceOkAddrspace(d: PageDb, n: PageNr, a: PageNr)
    requires n in d && d[n].PageDbEntryTyped? && d[n].entry.Addrspace?
    requires a in d && d[a].PageDbEntryTyped? && d[a].entry.Addrspace?
{
        ghost var addrspace := d[a].entry;
        n == a
        && addrspaceL1Unique(d, a)
        && addrspace.refcount == |addrspaceRefs(d, a)|
        && (stoppedAddrspace(d, n) ||  (
            d[addrspace.l1ptnr].PageDbEntryTyped? &&
            d[addrspace.l1ptnr].entry.L1PTable? &&
            d[addrspace.l1ptnr].addrspace == n
        ))
        // TODO CHECK L1PTPAGE UNIQUENESS HERE
}

predicate addrspaceOkL1PTable(d: PageDb, n: PageNr, a: PageNr)
    requires n in d && d[n].PageDbEntryTyped? && d[n].entry.L1PTable?
    requires a in d && d[a].PageDbEntryTyped? && d[a].entry.Addrspace?
{
    var e := d[n];
    var l1pt := e.entry.l1pt;
    // var addrspace := d[a].entry;
    // addrspace.l1ptnr == n &&
    forall pte :: pte in l1pt && pte.Just? ==> ( var pteE := fromJust(pte);
        pteE in d && d[pteE].PageDbEntryTyped? && d[pteE].addrspace == a)
}

predicate addrspaceOkL2PTable(d: PageDb, n: PageNr, a: PageNr)
    requires n in d && d[n].PageDbEntryTyped? && d[n].entry.L2PTable?
    requires a in d && d[a].PageDbEntryTyped? && d[a].entry.Addrspace?
{
    var e := d[n];
    var l2pt := e.entry.l2pt;
    forall pte :: pte in l2pt && pte.SecureMapping? ==> (
        var ptePg := pte.page;
        ptePg in d && d[ptePg].PageDbEntryTyped? && d[ptePg].addrspace == a)
}

predicate wellFormedPageDbEntry(d: PageDb, e: PageDbEntryTyped)
{
    (e.Addrspace? &&  validAddrspace(d, e))
    || (e.L1PTable? && validL1PTable(d, e))
    || (e.L2PTable? && validL2PTable(d, e))
    || (e.Dispatcher? )
    || (e.DataPage? )
}

// Free pages and non-addrspace entries should have a refcount of 0
predicate pageDbEntryValidRefs(d: PageDb, n: PageNr)
    requires n in d
{
    var e := d[n];
    (e.PageDbEntryTyped? && e.entry.Addrspace?) ||
        forall m : PageNr :: validPageNr(m) ==>
            |addrspaceRefs(d, n)| == 0
}

predicate validL1PTable(d: PageDb, e: PageDbEntryTyped)
    requires e.L1PTable?
    // requires var a := d[n].addrspace; a in d && d[a].PageDbEntryTyped? && d[a].entry.Addrspace?
{
    var l1pt := e.l1pt;
    // it's the right length (all page tables are this length)
    |l1pt| == NR_L1PTES()
    // each non-zero entry is a valid L2PT belonging to this address space
    && forall pte :: pte in l1pt && pte.Just? ==> validL1PTE(d, fromJust(pte))
    // no L2PT is referenced twice
    && forall i, j :: 0 <= i < |l1pt| && 0 <= j < |l1pt| && l1pt[i].Just? && i != j
        ==> l1pt[i] != l1pt[j]
}

predicate validL1PTE(d: PageDb, pte: PageNr)
{
    pte in d
        && d[pte].PageDbEntryTyped?
        && d[pte].entry.L2PTable?
}

predicate validL2PTable(d: PageDb, e: PageDbEntryTyped)
    requires e.L2PTable?
{
    var l2pt := e.l2pt;
    |l2pt| == NR_L2PTES()
    // each secure entry is a valid data page belonging to this address space
    && forall pte :: pte in l2pt && pte.SecureMapping?
        ==> validL2PTE(d, pte.page)
}

predicate validL2PTE(d: PageDb, pte: PageNr)
{
    pte in d
        && d[pte].PageDbEntryTyped?
        && d[pte].entry.DataPage?
}

predicate validAddrspacePage(d: PageDb, n: PageNr)
{
    n in d && d[n].PageDbEntryTyped? && d[n].entry.Addrspace? &&
        validAddrspace(d, d[n].entry)
}
   
predicate validAddrspace(d: PageDb, a: PageDbEntryTyped)
    requires a.Addrspace?
{
        a.state == StoppedState || 
        (validPageNr(a.l1ptnr)
        && a.l1ptnr in d
        && d[a.l1ptnr].PageDbEntryTyped?
        && d[a.l1ptnr].entry.L1PTable?)
}

predicate addrspaceL1Unique(d: PageDb, n: PageNr)
    requires n in d && d[n].PageDbEntryTyped? && d[n].entry.Addrspace?
{
    var a := d[n].entry;
    a.l1ptnr in d &&
    forall p :: p in d && p != a.l1ptnr &&
        d[p].PageDbEntryTyped? && d[p].addrspace == n ==>
        !d[p].entry.L1PTable?
}


// returns the number of references to an addrspace page with the given index
function addrspaceRefs(d: PageDb, addrspacePageNr: PageNr): set<PageNr>
    requires addrspacePageNr in d
{
    // XXX: inlined validPageNr(n) to help dafny see that this set is bounded
    (set n | 0 <= n < KEVLAR_SECURE_NPAGES() && n in d
        && d[n].PageDbEntryTyped?
        && n != addrspacePageNr
        && d[n].addrspace == addrspacePageNr)
}


function initialPageDb(): PageDb
  ensures validPageDb(initialPageDb())
{
  imap n: PageNr | validPageNr(n) :: PageDbEntryFree
}
