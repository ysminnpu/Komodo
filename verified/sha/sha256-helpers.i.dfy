// REQUIRES-ANY: TEST
// RUN: %DAFNY /compile:0 %s %DARGS

include "../valesupp.i.dfy"
include "../words_and_bytes.s.dfy"
include "../kom_common.s.dfy"
include "../sha/sha256.i.dfy"
include "../sha/bit-vector-lemmas.i.dfy"

function method Sigma0(i:int) : word
    requires 0 <= i < 3;
{
    [2, 13, 22][i]
}

function method Sigma1(i:int) : word
    requires 0 <= i < 3;
{
    [6, 11, 25][i]
}

function method sigma0(i:int) : word
    requires 0 <= i < 3;
{
    [7, 18, 3][i]
}

function method sigma1(i:int) : word
    requires 0 <= i < 3;
{
    [17, 19, 10][i]
}

type SHA_step = i | 0 <= i < 64

function method GetReg(r:int) : ARMReg
    requires 0 <= r <= 12;
{
         if r ==  0 then R0
    else if r ==  1 then R1
    else if r ==  2 then R2
    else if r ==  3 then R3
    else if r ==  4 then R4
    else if r ==  5 then R5
    else if r ==  6 then R6
    else if r ==  7 then R7
    else if r ==  8 then R8
    else if r ==  9 then R9
    else if r == 10 then R10
    else if r == 11 then R11
    else R12 
}

function{:opaque} OpaqueMod(x:int, y:int):int requires y > 0 { x % y }

function method CheapMod16(j:int) : int
{
    if j < 16 then j 
    else if j < 32 then j - 16 
    else if j < 48 then j - 32 
    else if j < 64 then j - 48 
    else j - 64
}

predicate method Even(i:int) { i % 2 == 0 }

type perm_index = i | 0 <= i < 8
function method ApplyPerm(i:int, perm:perm_index) : int
{
    //if i + perm >= 8 then i + perm - 8 else i + perm
    if i - perm >= 0 then i - perm else i - perm + 8
}

function SelectPerm(arr:seq<word>, i:int, perm:perm_index):word
    requires |arr| == 8
    requires 0 <= i < 8
{
    arr[if i + perm >= 8 then i + perm - 8 else i + perm]
}

function{:opaque} seq8(a:word, b:word, c:word, d:word, e:word, f:word, g:word, h:word):seq<word>
    ensures (var x := seq8(a, b, c, d, e, f, g, h); |x| == 8 && x[0] == a && x[1] == b && x[2] == c && x[3] == d && x[4] == e && x[5] == f && x[6] == g && x[7] == h)
{
    [a, b, c, d, e, f, g, h]
}

lemma lemma_BitwiseAdd32Commutes2(x1:word, x2:word)
    ensures BitwiseAdd32(x1, x2) == BitwiseAdd32(x2, x1);
{
}

lemma lemma_BitwiseAdd32Associates3'(x1:word, x2:word, x3:word)
    ensures BitwiseAdd32(BitwiseAdd32(x1, x2), x3) == BitwiseAdd32(x1, BitwiseAdd32(x2, x3));
{
    reveal TruncateWord();
    lemma_AddWrapAssociates(x1, x2, x3);
}

lemma lemma_BitwiseAdd32Associates3(x1:word, x2:word, x3:word)
    ensures BitwiseAdd32(BitwiseAdd32(x1, x2), x3) == BitwiseAdd32(BitwiseAdd32(x1, x3), x2);
{
    calc {
        BitwiseAdd32(BitwiseAdd32(x1, x2), x3);
            { lemma_BitwiseAdd32Associates3'(x1, x2, x3); }
        BitwiseAdd32(x1, BitwiseAdd32(x2, x3));
        BitwiseAdd32(x1, BitwiseAdd32(x3, x2));
            { lemma_BitwiseAdd32Associates3'(x1, x3, x2); }
        BitwiseAdd32(BitwiseAdd32(x1, x3), x2);
    }
}

lemma lemma_BitwiseAdd32Associates5(x1:word, x2:word, x3:word, x4:word, x5:word, result:word)
    requires result == BitwiseAdd32(BitwiseAdd32(BitwiseAdd32(BitwiseAdd32(x1, x2), x3), x4), x5);
    ensures  result == BitwiseAdd32(BitwiseAdd32(BitwiseAdd32(BitwiseAdd32(x1, x3), x5), x4), x2);
{
    calc {
        result;
        BitwiseAdd32(BitwiseAdd32(BitwiseAdd32(BitwiseAdd32(x1, x2), x3), x4), x5);
            { lemma_BitwiseAdd32Associates3(x1, x2, x3); }
        BitwiseAdd32(BitwiseAdd32(BitwiseAdd32(BitwiseAdd32(x1, x3), x2), x4), x5);
            { lemma_BitwiseAdd32Associates3(BitwiseAdd32(x1, x3), x2, x4); }
        BitwiseAdd32(BitwiseAdd32(BitwiseAdd32(BitwiseAdd32(x1, x3), x4), x2), x5);
            { lemma_BitwiseAdd32Associates3(BitwiseAdd32(BitwiseAdd32(x1, x3), x4), x2, x5); }
        BitwiseAdd32(BitwiseAdd32(BitwiseAdd32(BitwiseAdd32(x1, x3), x4), x5), x2);
            { lemma_BitwiseAdd32Associates3(BitwiseAdd32(x1, x3), x4, x5); }
        BitwiseAdd32(BitwiseAdd32(BitwiseAdd32(BitwiseAdd32(x1, x3), x5), x4), x2);
    }
}

lemma lemma_BitwiseAdd32Associates4(x1:word, x2:word, x3:word, x4:word, result:word)
    requires result == BitwiseAdd32(BitwiseAdd32(x4, BitwiseAdd32(x1, x3)), x2);
    ensures  result == BitwiseAdd32(BitwiseAdd32(BitwiseAdd32(x1, x2), x3), x4);
{
    calc {
        result ;
        BitwiseAdd32(BitwiseAdd32(x4, BitwiseAdd32(x1, x3)), x2);
            { lemma_BitwiseAdd32Commutes2(BitwiseAdd32(x1, x3), x4); }
        BitwiseAdd32(BitwiseAdd32(BitwiseAdd32(x1, x3), x4), x2);
            { lemma_BitwiseAdd32Associates3(BitwiseAdd32(x1, x3), x4, x2); }
        BitwiseAdd32(BitwiseAdd32(BitwiseAdd32(x1, x3), x2), x4);
            { lemma_BitwiseAdd32Associates3(x1, x3, x2); }
        BitwiseAdd32(BitwiseAdd32(BitwiseAdd32(x1, x2), x3), x4);
    }
}

lemma lemma_Even_properties(i:int)
    ensures Even(i) == !Even(i + 1);
{
}

lemma lemma_perm_properties(i:int, perm:perm_index)
    ensures 0 <= i < 8 ==> ApplyPerm(i, perm) == (i-perm)%8;
{
}

lemma lemma_perm_implications(i:int)
    ensures ApplyPerm(0, (i+1)%8) == ApplyPerm(7, i%8);
    ensures ApplyPerm(1, (i+1)%8) == ApplyPerm(0, i%8);
    ensures ApplyPerm(2, (i+1)%8) == ApplyPerm(1, i%8);
    ensures ApplyPerm(3, (i+1)%8) == ApplyPerm(2, i%8);
    ensures ApplyPerm(4, (i+1)%8) == ApplyPerm(3, i%8);
    ensures ApplyPerm(5, (i+1)%8) == ApplyPerm(4, i%8);
    ensures ApplyPerm(6, (i+1)%8) == ApplyPerm(5, i%8);
    ensures ApplyPerm(7, (i+1)%8) == ApplyPerm(6, i%8);
{
}

lemma lemma_obvious_WordAligned(i:int)
    requires WordAligned(i);
    ensures  WordAligned(i + 4);
{
}

lemma lemma_obvious_mod_with_constants(i:int)
    requires i == 64 || i == 16;
    ensures i % 8 == 0;
{
}

lemma lemma_mod_in_bounds(i:int, base:int, old_val:int, val:int)
    requires 0 <= i < 15;
    requires 0 <= base;
    requires old_val == base + (i + 1)*4;
    requires val == (old_val + 4) % 0x1_0000_0000;
    requires base + 16*4 < 0x1_0000_0000;
    ensures  val == base + (i + 2)*4;
{
    calc {
        val;
        (old_val + 4) % 0x1_0000_0000;
        (base + (i + 1)*4 + 4) % 0x1_0000_0000;
        (base + i*4 + 4 + 4) % 0x1_0000_0000;
        (base + (i+2)*4) % 0x1_0000_0000;
    }
    assert 0 <= base + (i+2) * 4 <= base + 16*4;
}

lemma lemma_mod_in_bounds2(i:int, base:int, old_val:int, val:int)
    requires 0 <= i < 64;
    requires 0 <= base;
    requires old_val == base + 4*i;
    requires val == (old_val + 4) % 0x1_0000_0000;
    requires base + 4*64 < 0x1_0000_0000;
    ensures  val == old_val + 4;
    //ensures  val == base + (i + 2)*4;
{
//    calc {
//        val;
//        (old_val + 4) % 0x1_0000_0000;
//        (base + (i + 1)*4 + 4) % 0x1_0000_0000;
//        (base + i*4 + 4 + 4) % 0x1_0000_0000;
//        (base + (i+2)*4) % 0x1_0000_0000;
//    }
//    assert 0 <= base + (i+2) * 4 <= base + 16*4;
}

lemma lemma_BitwiseAdd32_properties(w:word)
    ensures BitwiseAdd32(w, 0) == w;
{ reveal TruncateWord(); }

/*
lemma lemma_ValidSrcAddrsPreservation(old_mem:memmap, mem:memmap, base:nat, num_words:nat, taint:taint,
                                      update_addr1:nat, update_addr2:nat)
    requires ValidSrcAddrs(old_mem, base, num_words, taint);
    requires update_addr1 in mem;
    requires update_addr2 in mem;
    requires update_addr1 < base || update_addr1 >= base + num_words*4;
    requires update_addr2 < base || update_addr2 >= base + num_words*4;
    requires mem == old_mem[update_addr1 := mem[update_addr1]][update_addr2 := mem[update_addr2]];
    ensures  ValidSrcAddrs(mem, base, num_words, taint);
{
    forall addr | base <= addr < base + num_words*4 && (addr - base) % 4 == 0
        ensures ValidSrcAddr(mem, addr, taint)
    {
        assert ValidSrcAddr(old_mem, addr, taint);
    }
}

lemma lemma_ValidSrcAddrsIncrement(old_mem:memmap, mem:memmap, base:nat, num_words:nat, taint:taint,
                                   step:nat, update_addr1:nat, update_addr2:nat)
    requires 0 <= step < 64;
    requires num_words == 16;
    requires ValidAddrs(old_mem, base, num_words);
    requires ValidSrcAddrs(old_mem, base, (if step < 16 then step else 16), taint);
    requires update_addr1 in mem;
    requires update_addr2 in mem;
    requires update_addr1 < base || update_addr1 >= base + num_words*4;
    requires update_addr2 == base + CheapMod16(step) * 4;
    requires mem == old_mem[update_addr1 := mem[update_addr1]][update_addr2 := mem[update_addr2]];
    requires mem[update_addr2].t == taint;
    ensures ValidSrcAddrs(mem, base, (if step + 1 < 16 then step + 1 else 16), taint);
{
    var i_orig := (if step < 16 then step else 16);
    var i_new := (if step + 1 < 16 then step + 1 else 16);
    forall addr | base <= addr < base + i_new*4 && (addr - base) % 4 == 0
        ensures ValidSrcAddr(mem, addr, taint)
    {
        if addr < update_addr2 {
            assert ValidSrcAddr(old_mem, addr, taint);
            assert ValidSrcAddr(mem, addr, taint);
        } else {
             assert ValidAddr(old_mem, addr);
//            assert update_addr2 <= addr < base + i_new*4;
//            assert base + CheapMod16'(step) * 4 <= addr < base + (if step + 1 < 16 then step + 1 else 16)*4;
//            if step + 1 < 16 {
//                assert base + step * 4 <= addr < base + (step + 1)*4;
//                assert addr == update_addr2;
//                assert i_new <= num_words;
//                assert base <= addr < base + num_words*4 && (addr - base) % 4 == 0;
//                assert ValidAddr(old_mem, addr);
//                assert ValidSrcAddr(mem, addr, taint);
//            } else if step < 16 {
//                assert step == 15;
//                assert base + 15 * 4 <= addr < base + 16*4;
//                assert addr == update_addr2;
//                assert ValidAddr(old_mem, addr);
//                assert ValidSrcAddr(mem, addr, taint);
//            } else {
//                assert step == 16;
//                assert base  <= addr < base + 16*4;
//                assert ValidAddr(old_mem, addr);
//                assert ValidSrcAddr(mem, addr, taint);
//            }
        }
    }
}
*/
predicate InputMatchesMemory(input:seq<word>, input_ptr:addr, num_words:nat, mem:memmap)
    requires ValidAddrMemStateOpaque(mem)
    requires isUInt32(WordOffset'(input_ptr, num_words))
    requires ValidMemRange(input_ptr, WordOffset(input_ptr, num_words))
    requires |input| >= num_words;
{
    // forall j {:trigger ValidMem(input_ptr+j*WORDSIZE)} {:trigger AddrMemContents(mem, input_ptr + j*WORDSIZE)} :: 0 <= j < num_words ==> AddrMemContents(mem, input_ptr + j*WORDSIZE) == input[j]
    //forall j:int, a:addr :: 0 <= j < num_words && a == input_ptr + j * WORDSIZE && input_ptr <= a <= input_ptr + num_words * WORDSIZE ==> AddrMemContents(mem, a) == input[j]
    forall j :: 0 <= j < num_words ==> AddrMemContents(mem, WordOffset(input_ptr, j)) == input[j]
}

lemma lemma_InputPreservation(old_mem:memmap, mem:memmap, input:seq<word>, input_ptr:addr, num_words:nat,
                              update_addr1:nat, update_addr2:nat)
    requires ValidAddrMemStateOpaque(old_mem);
    requires ValidAddrMemStateOpaque(mem);
    requires isUInt32(WordOffset'(input_ptr, num_words))
    requires ValidMemRange(input_ptr, WordOffset(input_ptr, num_words))
    requires |input| >= num_words;
    requires InputMatchesMemory(input, input_ptr, num_words, old_mem);
    requires ValidMem(update_addr1);
    requires ValidMem(update_addr2);
    requires update_addr1 < input_ptr || update_addr1 >= WordOffset(input_ptr, num_words);
    requires update_addr2 < input_ptr || update_addr2 >= WordOffset(input_ptr, num_words);
    requires mem == AddrMemUpdate(AddrMemUpdate(old_mem, update_addr1, AddrMemContents(mem, update_addr1)), update_addr2, AddrMemContents(mem, update_addr2));
    ensures  InputMatchesMemory(input, input_ptr, num_words, mem);
{
    assert forall j :: 0 <= j < num_words
        ==> AddrMemContents(old_mem, WordOffset(input_ptr, j)) == AddrMemContents(mem, WordOffset(input_ptr, j));
}

predicate WsMatchMemory(trace:SHA256Trace, i:int, base:addr, mem:memmap)
    requires 0 <= i <= 64;
    requires |trace.W| > 0;
    requires |last(trace.W)| == 64
    requires isUInt32(WordOffset'(base, 19))
    requires ValidMemRange(base, WordOffset(base, 19));
    requires ValidAddrMemStateOpaque(mem);
{
    (i < 16 ==> (forall j :: 0 <= j < i ==> last(trace.W)[j] == AddrMemContents(mem, WordOffset(base, j))))
 && (16 <= i < 64 ==> (forall j :: i - 16 <= j < i ==> last(trace.W)[j] == AddrMemContents(mem, WordOffset(base, CheapMod16(j)))))
}

lemma lemma_WsIncrement(old_mem:memmap, mem:memmap, trace1:SHA256Trace, trace2:SHA256Trace, base:addr,
                        step:nat, update_addr1:nat, update_addr2:nat)
    requires 0 <= step < 64;
    requires |trace1.W| > 0;
    requires |last(trace1.W)| == 64
    requires isUInt32(WordOffset'(base, 19))
    requires ValidMemRange(base, WordOffset(base, 19));
    requires ValidAddrMemStateOpaque(old_mem);
    requires ValidAddrMemStateOpaque(mem);
    requires |trace2.W| > 0;
    requires last(trace2.W) == last(trace1.W);
    requires WsMatchMemory(trace1, step, base, old_mem);
    requires ValidMem(update_addr1);
    requires ValidMem(update_addr2);
    requires update_addr1 < base || update_addr1 >= WordOffset(base, 16);
    requires update_addr2 == WordOffset(base, CheapMod16(step));
    requires mem == AddrMemUpdate(AddrMemUpdate(old_mem, update_addr1, AddrMemContents(mem, update_addr1)), update_addr2, AddrMemContents(mem, update_addr2));
    requires AddrMemContents(mem, update_addr2) == last(trace1.W)[step];
    ensures  WsMatchMemory(trace2, step + 1, base, mem);
{
}

// TODO: Need to import sha256_unique.i.dfy from Vale
lemma {:axiom} lemma_SHA256IsAFunction(message:seq<byte>, hash:seq<word>)
    requires |message| <= MaxBytesForSHA();
    requires IsSHA256(message, hash);
    ensures  SHA256(message) == hash;

