include "ARMdef.dfy"

//-----------------------------------------------------------------------------
// Spartan Types
//-----------------------------------------------------------------------------
type sp_int = int
type sp_bool = bool
type sp_operand = operand 
type sp_cmp = obool
type sp_code = code
type sp_codes = codes
type sp_state = state

//-----------------------------------------------------------------------------
// Spartan-Verification Interface
//-----------------------------------------------------------------------------
function sp_eval_op(s:state, o:operand):int
    requires ValidState(s)
    requires ValidOperand(o)
    { OperandContents(s, o) }

predicate sp_eq_ops(s1:sp_state, s2:sp_state, o:operand)
{
    ValidState(s1) && ValidState(s2) && ValidOperand(o)
        && sp_eval_op(s1, o) == sp_eval_op(s2, o)
}

function sp_eval_mem(s:state, m:mem):int
    requires ValidMemState(s.m);
    requires ValidMem(s.m, m);
    ensures isUInt32(sp_eval_mem(s,m));
    { MemContents(s.m, m) }

function method sp_CNil():codes { CNil }
function sp_cHead(b:codes):code requires b.sp_CCons? { b.hd }
predicate sp_cHeadIs(b:codes, c:code) { b.sp_CCons? && b.hd == c }
predicate sp_cTailIs(b:codes, t:codes) { b.sp_CCons? && b.tl == t }

function method fromOperand(o:operand):operand { o }
function method sp_op_const(n:int):operand { OConst(n) }

function method sp_cmp_eq(o1:operand, o2:operand):obool { OCmp(OEq, o1, o2) }
function method sp_cmp_ne(o1:operand, o2:operand):obool { OCmp(ONe, o1, o2) }
function method sp_cmp_le(o1:operand, o2:operand):obool { OCmp(OLe, o1, o2) }
function method sp_cmp_ge(o1:operand, o2:operand):obool { OCmp(OGe, o1, o2) }
function method sp_cmp_lt(o1:operand, o2:operand):obool { OCmp(OLt, o1, o2) }
function method sp_cmp_gt(o1:operand, o2:operand):obool { OCmp(OGt, o1, o2) }

function method sp_Block(block:codes):code { Block(block) }
function method sp_IfElse(ifb:obool, ift:code, iff:code):code { IfElse(ifb, ift, iff) }
function method sp_While(whileb:obool, whilec:code):code { While(whileb, whilec) }

function method sp_get_block(c:code):codes requires c.Block? { c.block }
function method sp_get_ifCond(c:code):obool requires c.IfElse? { c.ifCond }
function method sp_get_ifTrue(c:code):code requires c.IfElse? { c.ifTrue }
function method sp_get_ifFalse(c:code):code requires c.IfElse? { c.ifFalse }
function method sp_get_whileCond(c:code):obool requires c.While? { c.whileCond }
function method sp_get_whileBody(c:code):code requires c.While? { c.whileBody }

//-----------------------------------------------------------------------------
// Address Helper Functions
//-----------------------------------------------------------------------------
function addrval(s:state, a:int):int
    requires ValidState(s)
    requires ValidMem(s.m, a)
    ensures isUInt32(addrval(s, a))
{
    MemContents(s.m, a)
}

function addr_mem(s:state, base:operand, ofs:operand):mem
    requires ValidState(s)
    requires ValidOperand(base)
    requires ValidOperand(ofs)
{
    OperandContents(s, base) + OperandContents(s, ofs)
}

//-----------------------------------------------------------------------------
// Useful invariants preserved by instructions
//-----------------------------------------------------------------------------
predicate AlwaysInvariant(s:state, s':state)
{
    // valid state is maintained
    ValidState(s) && ValidState(s')
    // mem validity never changes
    && (forall m:mem :: m in s.m.addresses <==> m in s'.m.addresses)
}

predicate ModeInvariant(s:state, s':state)
    requires ValidState(s) && ValidState(s')
{
    mode_of_state(s) == mode_of_state(s')
}

predicate WorldInvariant(s:state, s':state)
    requires ValidState(s) && ValidState(s')
{
    world_of_state(s) == world_of_state(s')
}

predicate AllMemInvariant(s:state, s':state)
    requires ValidState(s) && ValidState(s')
{
    s.m == s'.m
}

predicate GlobalsInvariant(s:state, s':state)
    requires ValidState(s) && ValidState(s')
{
    s.m.globals == s'.m.globals
}

predicate AddrMemInvariant(s:state, s':state)
    requires ValidState(s) && ValidState(s')
{
    s.m.addresses == s'.m.addresses
}

//-----------------------------------------------------------------------------
// Instructions
//-----------------------------------------------------------------------------
function method{:opaque} sp_code_ADD(dst:operand, src1:operand,
    src2:operand):code { Ins(ADD(dst, src1, src2)) }

function method{:opaque} sp_code_SUB(dst:operand, src1:operand,
    src2:operand):code { Ins(SUB(dst, src1, src2)) }

function method{:opaque} sp_code_MUL(dst:operand, src1:operand,
    src2:operand):code { Ins(MUL(dst, src1, src2)) }

function method{:opaque} sp_code_UDIV(dst:operand, src1:operand,
    src2:operand):code { Ins(UDIV(dst, src1, src2)) }

function method{:opaque} sp_code_AND(dst:operand, src1:operand,
    src2:operand):code { Ins(AND(dst, src1, src2)) }

function method{:opaque} sp_code_ORR(dst:operand, src1:operand,
    src2:operand):code { Ins(ORR(dst, src1, src2)) }

function method{:opaque} sp_code_EOR(dst:operand, src1:operand,
    src2:operand):code { Ins(EOR(dst, src1, src2)) }

function method{:opaque} sp_code_ROR(dst:operand, src1:operand,
    src2:operand):code { Ins(ROR(dst, src1, src2)) }

function method{:opaque} sp_code_LSL(dst:operand, src1:operand,
    src2:operand):code { Ins(LSL(dst, src1, src2)) }

function method{:opaque} sp_code_LSR(dst:operand, src1:operand,
    src2:operand):code { Ins(LSR(dst, src1, src2)) }

function method{:opaque} sp_code_MVN(dst:operand, src:operand):code
    { Ins(MVN(dst, src)) }

function method{:opaque} sp_code_MOV(dst:operand, src:operand):code
    { Ins(MOV(dst, src)) }

function method{:opaque} sp_code_LDR(rd:operand, base:operand, ofs:operand):code
    { Ins(LDR(rd, base, ofs)) }

function method{:opaque} sp_code_LDRglobal(rd:operand, global:operand, base:operand, ofs:operand):code
    { Ins(LDR_global(rd, global, base, ofs)) }

function method{:opaque} sp_code_STR(rd:operand, base:operand, ofs:operand):code
    { Ins(STR(rd, base, ofs)) }

function method{:opaque} sp_code_STRglobal(rd:operand, global:operand, base:operand, ofs:operand):code
    { Ins(STR_global(rd, global, base, ofs)) }

// function method{:opaque} sp_code_CPS(mod:operand):code
//     { Ins(CPS(mod)) }

function method{:opaque} sp_code_MRS(dst:operand, src:operand):code
    { Ins(MRS(dst, src)) }

function method{:opaque} sp_code_MSR(dst:operand, src:operand):code
    { Ins(MSR(dst, src)) }

function method{:opaque} sp_code_MRC(dst:operand,src:operand):code
    { Ins(MRC(dst, src)) }

function method{:opaque} sp_code_MCR(dst:operand,src:operand):code
    { Ins(MCR(dst, src)) }

function method{:opaque} sp_code_MOVS_PCLR():code
    { Ins(MOVS_PCLR()) }

// Pseudoinstructions  
function method{:opaque} sp_code_plusEquals(o1:operand, o2:operand):code { Ins(ADD(o1, o1, o2)) }
// function method{:opaque} sp_code_push(o:operand):code { 
//     // Ins(SUB(OSP, OSP, OConst(4)))
//     var i1 := Ins(SUB(OSP, OSP, OConst(4)));
//     var i2 := Ins(STR(o, OSP, OConst(0)));
//     Block(sp_CCons( i1, sp_CCons(i2, CNil) ))
// }

function method{:opaque} sp_code_LDRglobaladdr(rd:operand, g:operand):code
    { Ins(LDR_reloc(rd, g)) }

//-----------------------------------------------------------------------------
// Instruction Lemmas
//-----------------------------------------------------------------------------
lemma sp_lemma_ADD(s:state, r:state, ok:bool,
    dst:operand, src1:operand, src2:operand)
    requires ValidState(s);
    requires ValidOperand(src1);
    requires ValidOperand(src2);
    requires ValidDestinationOperand(dst);
    requires isUInt32(OperandContents(s, src1) + OperandContents(s, src2));
    requires sp_eval(sp_code_ADD(dst, src1, src2), s, r, ok);
    ensures  evalUpdate(s, dst, OperandContents(s, src1) +
        OperandContents(s, src2), r, ok);
    ensures ok;
    ensures AlwaysInvariant(s, r);
    ensures AllMemInvariant(s, r);
    ensures ModeInvariant(s, r);
{
    reveal_sp_eval();
    reveal_sp_code_ADD();
}

lemma sp_lemma_SUB(s:state, r:state, ok:bool,
    dst:operand, src1:operand, src2:operand)
    requires ValidState(s);
    requires ValidOperand(src1);
    requires ValidOperand(src2);
    requires ValidDestinationOperand(dst);
    requires sp_eval(sp_code_SUB(dst, src1, src2), s, r, ok);
    requires isUInt32(OperandContents(s, src1) - OperandContents(s, src2));
    ensures  evalUpdate(s, dst, OperandContents(s, src1) -
        OperandContents(s, src2), r, ok);
    ensures ok;
    ensures AlwaysInvariant(s, r);
    ensures AllMemInvariant(s, r);
    ensures ModeInvariant(s, r);
{
    reveal_sp_eval();
    reveal_sp_code_SUB();
}

lemma sp_lemma_MUL(s:state, r:state, ok:bool,
    dst:operand, src1:operand, src2:operand)
    requires ValidState(s);
    requires ValidRegOperand(src1);
    requires ValidRegOperand(src2);
    requires ValidDestinationOperand(dst);
    requires sp_eval(sp_code_MUL(dst, src1, src2), s, r, ok);
    requires isUInt32(OperandContents(s, src1) * OperandContents(s, src2));
    ensures  evalUpdate(s, dst, OperandContents(s, src1) *
        OperandContents(s, src2), r, ok);
    ensures ok;
    ensures AlwaysInvariant(s, r);
    ensures AllMemInvariant(s, r);
    ensures ModeInvariant(s, r);
{
    reveal_sp_eval();
    reveal_sp_code_MUL();
}

lemma sp_lemma_UDIV(s:state, r:state, ok:bool,
    dst:operand, src1:operand, src2:operand)
    requires ValidState(s);
    requires ValidOperand(src1);
    requires ValidOperand(src2);
    requires ValidDestinationOperand(dst);
    requires OperandContents(s,src2) > 0;
    requires sp_eval(sp_code_UDIV(dst, src1, src2), s, r, ok);
    requires isUInt32(OperandContents(s, src1) / OperandContents(s, src2));
    ensures  evalUpdate(s, dst, OperandContents(s, src1) /
        OperandContents(s, src2), r, ok);
    ensures ok;
    ensures AlwaysInvariant(s, r);
    ensures AllMemInvariant(s, r);
    ensures ModeInvariant(s, r);
{
    reveal_sp_eval();
    reveal_sp_code_UDIV();
}

lemma sp_lemma_AND(s:state, r:state, ok:bool,
    dst:operand, src1:operand, src2:operand)
    requires ValidState(s);
    requires ValidOperand(src1);
    requires ValidOperand(src2);
    requires ValidDestinationOperand(dst);
    requires sp_eval(sp_code_AND(dst, src1, src2), s, r, ok);
    ensures evalUpdate(s, dst, and32(eval_op(s, src1),
        eval_op(s, src2)), r, ok);
    ensures ok;
    ensures AlwaysInvariant(s, r);
    ensures AllMemInvariant(s, r);
    ensures ModeInvariant(s, r);
{
    reveal_sp_eval();
    reveal_sp_code_AND();
}

lemma sp_lemma_ORR(s:state, r:state, ok:bool,
    dst:operand, src1:operand, src2:operand)
    requires ValidState(s);
    requires ValidOperand(src1);
    requires ValidOperand(src2);
    requires ValidDestinationOperand(dst);
    requires sp_eval(sp_code_ORR(dst, src1, src2), s, r, ok);
    ensures evalUpdate(s, dst, or32(eval_op(s, src1),
        eval_op(s, src2)), r, ok);
    ensures ok;
    ensures AlwaysInvariant(s, r);
    ensures AllMemInvariant(s, r);
    ensures ModeInvariant(s, r);
{
    reveal_sp_eval();
    reveal_sp_code_ORR();
}

lemma sp_lemma_EOR(s:state, r:state, ok:bool,
    dst:operand, src1:operand, src2:operand)
    requires ValidState(s);
    requires ValidOperand(src1);
    requires ValidOperand(src2);
    requires ValidDestinationOperand(dst);
    requires sp_eval(sp_code_EOR(dst, src1, src2), s, r, ok);
    ensures evalUpdate(s, dst, xor32(eval_op(s, src1),
        eval_op(s, src2)), r, ok);
    ensures ok;
    ensures AlwaysInvariant(s, r);
    ensures AllMemInvariant(s, r);
    ensures ModeInvariant(s, r);
{
    reveal_sp_eval();
    reveal_sp_code_EOR();
}

lemma sp_lemma_ROR(s:state, r:state, ok:bool,
    dst:operand, src1:operand, src2:operand)
    requires ValidState(s);
    requires ValidOperand(src1);
    requires ValidShiftOperand(s,src2);
    requires ValidDestinationOperand(dst);
    requires sp_eval(sp_code_ROR(dst, src1, src2), s, r, ok);
    requires src2.OConst?;
    ensures evalUpdate(s, dst, ror32(eval_op(s, src1),
        eval_op(s, src2)), r, ok);
    ensures ok;
    ensures AlwaysInvariant(s, r);
    ensures AllMemInvariant(s, r);
    ensures ModeInvariant(s, r);
{
    reveal_sp_eval();
    reveal_sp_code_ROR();
}

lemma sp_lemma_LSL(s:state, r:state, ok:bool,
    dst:operand, src1:operand, src2:operand)
    requires ValidState(s);
    requires ValidOperand(src1);
    requires ValidShiftOperand(s,src2);
    requires ValidDestinationOperand(dst);
    requires sp_eval(sp_code_LSL(dst, src1, src2), s, r, ok);
    requires src2.OConst?;
    ensures evalUpdate(s, dst, shl32(eval_op(s, src1),
        eval_op(s, src2)), r, ok);
    ensures ok;
    ensures AlwaysInvariant(s, r);
    ensures AllMemInvariant(s, r);
    ensures ModeInvariant(s, r);
{
    reveal_sp_eval();
    reveal_sp_code_LSL();
}

lemma sp_lemma_LSR(s:state, r:state, ok:bool,
    dst:operand, src1:operand, src2:operand)
    requires ValidState(s);
    requires ValidOperand(src1);
    requires ValidShiftOperand(s,src2);
    requires ValidDestinationOperand(dst);
    requires sp_eval(sp_code_LSR(dst, src1, src2), s, r, ok);
    requires src2.OConst?;
    ensures evalUpdate(s, dst, shr32(eval_op(s, src1),
        eval_op(s, src2)), r, ok);
    ensures ok;
    ensures AlwaysInvariant(s, r);
    ensures AllMemInvariant(s, r);
    ensures ModeInvariant(s, r);
{
    reveal_sp_eval();
    reveal_sp_code_LSR();
}

lemma sp_lemma_MVN(s:state, r:state, ok:bool,
    dst:operand, src:operand)
    requires ValidState(s);
    requires ValidOperand(src);
    requires ValidDestinationOperand(dst);
    requires sp_eval(sp_code_MVN(dst, src), s, r, ok);
    ensures evalUpdate(s, dst, not32(eval_op(s, src)),
        r, ok);
    ensures ok;
    ensures AlwaysInvariant(s, r);
    ensures AllMemInvariant(s, r);
    ensures ModeInvariant(s, r);
{
    reveal_sp_eval();
    reveal_sp_code_MVN();
}

lemma sp_lemma_MOV(s:state, r:state, ok:bool,
    dst:operand, src:operand)
    requires ValidState(s);
    requires ValidOperand(src);
    requires ValidDestinationOperand(dst);
    requires sp_eval(sp_code_MOV(dst, src), s, r, ok);
    ensures evalUpdate(s, dst, OperandContents(s, src), r, ok);
    ensures ok;
    ensures AlwaysInvariant(s, r);
    ensures AllMemInvariant(s, r);
    ensures ModeInvariant(s, r);
{
    reveal_sp_eval();
    reveal_sp_code_MOV();
}

lemma sp_lemma_LDR(s:state, r:state, ok:bool,
    rd:operand, base:operand, ofs:operand)
    requires ValidState(s);
    requires ValidDestinationOperand(rd);
    requires ValidOperand(base);
    requires ValidOperand(ofs);
    requires WordAligned(OperandContents(s, base) + OperandContents(s, ofs));
    requires ValidMem(s.m, addr_mem(s, base, ofs));
    requires sp_eval(sp_code_LDR(rd, base, ofs), s, r, ok);
    ensures evalUpdate(s, rd, MemContents(s.m, OperandContents(s, base) + OperandContents(s, ofs)), r, ok)
    ensures ok;
    ensures AlwaysInvariant(s, r);
    ensures AllMemInvariant(s, r);
    ensures ModeInvariant(s, r);
{
    reveal_sp_eval();
    reveal_sp_code_LDR();
}

lemma sp_lemma_LDRglobal(s:state, r:state, ok:bool,
    rd:operand, g:operand, base:operand, ofs:operand)
    requires ValidState(s);
    requires ValidDestinationOperand(rd);
    requires ValidOperand(base);
    requires ValidOperand(ofs);
    requires ValidGlobalOffset(g, OperandContents(s, ofs));
    requires AddressOfGlobal(g) == OperandContents(s, base);
    requires sp_eval(sp_code_LDRglobal(rd, g, base, ofs), s, r, ok);
    ensures evalUpdate(s, rd, GlobalWord(s.m, g, OperandContents(s, ofs)), r, ok);
    ensures ok;
    ensures AlwaysInvariant(s, r);
    ensures AllMemInvariant(s, r);
    ensures ModeInvariant(s, r);
{
    reveal_sp_eval();
    reveal_sp_code_LDRglobal();
}

lemma sp_lemma_STR(s:state, r:state, ok:bool,
    rd:operand, base:operand, ofs:operand)
    requires ValidState(s);
    requires ValidRegOperand(rd);
    requires ValidOperand(base);
    requires ValidOperand(ofs);
    requires WordAligned(OperandContents(s, base) + OperandContents(s, ofs));
    requires ValidMem(s.m, addr_mem(s, base, ofs));
    requires sp_eval(sp_code_STR(rd, base, ofs), s, r, ok);
    ensures evalMemUpdate(s, OperandContents(s, base) + OperandContents(s, ofs),
        OperandContents(s, rd), r, ok)
    ensures ok;
    ensures AlwaysInvariant(s, r);
    ensures GlobalsInvariant(s, r);
    ensures ModeInvariant(s, r);
{
    reveal_sp_eval();
    reveal_sp_code_STR();
}

lemma sp_lemma_STRglobal(s:state, r:state, ok:bool,
    rd:operand, g:operand, base:operand, ofs:operand)
    requires ValidState(s);
    requires ValidRegOperand(rd);
    requires ValidOperand(base);
    requires ValidOperand(ofs);
    requires ValidGlobalOffset(g, OperandContents(s, ofs));
    requires AddressOfGlobal(g) == OperandContents(s, base);
    requires sp_eval(sp_code_STRglobal(rd, g, base, ofs), s, r, ok);
    ensures evalGlobalUpdate(s, g, OperandContents(s, ofs), OperandContents(s, rd), r, ok);
    ensures ok;
    ensures AlwaysInvariant(s, r);
    ensures ModeInvariant(s, r);
    ensures AddrMemInvariant(s, r);
{
    reveal_sp_eval();
    reveal_sp_code_STRglobal();
}

// lemma sp_lemma_CPS(s:state, r:state, ok:bool, mod:operand)
//     requires ValidState(s);
//     requires ValidOperand(mod);
//     requires sp_eval(sp_code_CPS(mod), s, r, ok);
//     requires ValidModeEncoding(OperandContents(s, mod));
//     ensures  evalModeUpdate(s, OperandContents(s, mod), r, ok);
//     ensures ok;
//     ensures AlwaysInvariant(s, r);
//     ensures AllMemInvariant(s, r);
// {
//     reveal_sp_eval();
//     reveal_sp_code_CPS();
// }

lemma sp_lemma_MRS(s:state, r:state, ok:bool,
    dst:operand, src: operand)
    requires ValidState(s)
    requires ValidSpecialOperand(s, src)
    requires !ValidMcrMrcOperand(s, src)
    requires ValidRegOperand(dst)
    requires sp_eval(sp_code_MRS(dst, src), s, r, ok)
    ensures evalUpdate(s, dst, SpecialOperandContents(s, src), r, ok)
    ensures ok;
{
    reveal_sp_eval();
    reveal_sp_code_MRS();
}

lemma sp_lemma_MSR(s:state, r:state, ok:bool,
    dst:operand, src: operand)
    requires ValidState(s)
    requires ValidRegOperand(src)
    requires ValidSpecialOperand(s, dst)
    requires !ValidMcrMrcOperand(s, dst)
    requires dst.sr.cpsr? || dst.sr.spsr? ==>
        ValidModeChange(mode_of_state(s), OperandContents(s, src))
    requires sp_eval(sp_code_MSR(dst, src), s, r, ok)
    ensures evalSRegUpdate(s, dst, OperandContents(s, src), r, ok)
    ensures ok;
{
    reveal_sp_eval();
    reveal_sp_code_MSR();
}

lemma sp_lemma_MRC(s:state, r:state, ok:bool, dst:operand, src:operand)
    requires ValidState(s);
    requires ValidRegOperand(dst);
    requires ValidMcrMrcOperand(s, src)
    requires sp_eval(sp_code_MRC(dst,src), s, r, ok);
    ensures  evalUpdate(s, dst, SpecialOperandContents(s, src), r, ok);
    ensures  ok;
{
    reveal_sp_eval();
    reveal_sp_code_MRC();
}

lemma sp_lemma_MCR(s:state, r:state, ok:bool, dst:operand, src:operand)
    requires ValidState(s)
    requires ValidRegOperand(src)
    requires ValidMcrMrcOperand(s, dst)
    requires sp_eval(sp_code_MCR(dst,src), s, r, ok)
    ensures  evalSRegUpdate(s, OSReg(scr), OperandContents(s,src), r, ok)
    ensures  ok;
{
    reveal_sp_eval();
    reveal_sp_code_MCR();
}

lemma sp_lemma_MOVS_PCLR(s:state, r:state, ok:bool)
    requires ValidState(s)
    requires var m := mode_of_state(s); var spsr := OSReg(spsr(m));
        ValidSpecialOperand(s, spsr) &&
        !(mode_of_state(s) == User) &&
        ValidModeChange(m, SpecialOperandContents(s, spsr))
    requires sp_eval(sp_code_MOVS_PCLR(), s, r, ok)
    ensures var spsr := OSReg(spsr(mode_of_state(s)));
        evalSRegUpdate(s, OSReg(cpsr), SpecialOperandContents(s,spsr), r, ok)
    ensures  ok;
{
    reveal_sp_eval();
    reveal_sp_code_MOVS_PCLR();
}

// Lemmas for frontend functions
// lemma sp_lemma_incr(s:sp_state, r:sp_state, ok:bool, o:operand)
//     requires ValidState(s);
//     requires ValidDestinationOperand(o)
//     requires sp_eval(sp_code_incr(o), s, r, ok)
//     requires isUInt32(eval_op(s, o) + 1);
//     ensures  evalUpdate(s, o, OperandContents(s, o) + 1, r, ok)
// {
//     reveal_sp_eval();
//     reveal_sp_code_incr();
// }

// lemma sp_lemma_push(s:sp_state, r:sp_state, ok:bool, o:operand)
//     requires ValidDestinationOperand(OSP)
//     requires ValidOperand(o)
//     requires sp_eval(sp_code_push(o), s, r, ok)
//     requires 4 <= eval_op(s, o) < MaxVal()
//     requires ValidMem(s, Address(eval_op(s, OSP)))
//     ensures ok;
//     ensures  evalMemUpdate(s, Address(eval_op(s, OSP)),
//         eval_op(s, o), r, ok)
//     ensures  evalUpdate(s, OSP, eval_op(s, OSP) - 4, r, ok)
//     ensures  eval_op(r, OSP) == eval_op(s, OSP) - 4
//     ensures  addrval(r, eval_op(s, OSP)) == eval_op(s, o)
// {
//     reveal_sp_eval();
//     reveal_sp_code_push();
// }

lemma sp_lemma_plusEquals(s:sp_state, r:sp_state, ok:bool, o1:operand, o2:operand)
    requires ValidState(s);
    requires ValidDestinationOperand(o1);
    requires ValidOperand(o2);
    requires sp_eval(sp_code_plusEquals(o1, o2), s, r, ok);
    requires isUInt32(OperandContents(s, o1) + OperandContents(s, o2));
    ensures evalUpdate(s, o1, OperandContents(s, o1) +
        OperandContents(s, o2), r, ok);
    ensures ok;
    ensures AlwaysInvariant(s, r);
    ensures AllMemInvariant(s, r);
    ensures ModeInvariant(s, r);
{
    reveal_sp_eval();
    reveal_sp_code_plusEquals();
}

lemma sp_lemma_LDRglobaladdr(s:state, r:state, ok:bool, rd:operand, g:operand)
    requires ValidState(s);
    requires ValidDestinationOperand(rd);
    requires ValidGlobal(g);
    requires sp_eval(sp_code_LDRglobaladdr(rd, g), s, r, ok);
    ensures evalUpdate(s, rd, AddressOfGlobal(g), r, ok);
    ensures ok;
    ensures AlwaysInvariant(s, r);
    ensures AllMemInvariant(s, r);
    ensures ModeInvariant(s, r);
{
    reveal_sp_eval();
    reveal_sp_code_LDRglobaladdr();
}


//-----------------------------------------------------------------------------
// Control Flow Lemmas
//-----------------------------------------------------------------------------

lemma sp_lemma_empty(s:state, r:state, ok:bool)
  requires sp_eval(Block(sp_CNil()), s, r, ok)
  ensures  ok
  ensures  r == s
{
  reveal_sp_eval();
}

lemma sp_lemma_block(b:codes, s0:state, r:state, ok:bool) returns(r1:state, ok1:bool, c0:code, b1:codes)
  requires b.sp_CCons?
  requires sp_eval(Block(b), s0, r, ok)
  ensures  b == sp_CCons(c0, b1)
  ensures  sp_eval(c0, s0, r1, ok1)
  ensures  ok1 ==> sp_eval(Block(b1), r1, r, ok)
{
  reveal_sp_eval();
  assert evalBlock(b, s0, r, ok);
  r1, ok1 :| evalCode(b.hd, s0, r1, ok1) && (if !ok1 then !ok else evalBlock(b.tl, r1, r, ok));
  c0 := b.hd;
  b1 := b.tl;
}

lemma sp_lemma_ifElse(ifb:obool, ct:code, cf:code, s:state, r:state, ok:bool) returns(cond:bool, s':sp_state)
  requires ValidState(s);
  requires ValidOperand(ifb.o1);
  requires ValidOperand(ifb.o2);
  requires sp_eval(IfElse(ifb, ct, cf), s, r, ok)
  ensures s' == s; // evalGuard
  ensures  cond == evalOBool(s, ifb)
  ensures  (if cond then sp_eval(ct, s, r, ok) else sp_eval(cf, s, r, ok))
{
  reveal_sp_eval();
  cond := evalOBool(s, ifb);
  s' := s;
}

// HACK
lemma unpack_eval_while(b:obool, c:code, s:state, r:state, ok:bool)
  requires evalCode(While(b, c), s, r, ok)
  ensures  exists n:nat :: evalWhile(b, c, n, s, r, ok)
{
}

predicate{:opaque} evalWhileOpaque(b:obool, c:code, n:nat, s:state, r:state, ok:bool) { evalWhile(b, c, n, s, r, ok) }

predicate sp_whileInv(b:obool, c:code, n:int, r1:state, ok1:bool, r2:state, ok2:bool)
{
  n >= 0 && ok1 && evalWhileOpaque(b, c, n, r1, r2, ok2)
}

lemma sp_lemma_while(b:obool, c:code, s:state, r:state, ok:bool) returns(n:nat, r':state, ok':bool)
  requires ValidOperand(b.o1)
  requires ValidOperand(b.o2)
  requires sp_eval(While(b, c), s, r, ok)
  ensures  evalWhileOpaque(b, c, n, s, r, ok)
  ensures  ok'
  ensures  r' == s
{
  reveal_sp_eval();
  reveal_evalWhileOpaque();
  unpack_eval_while(b, c, s, r, ok);
  n :| evalWhile(b, c, n, s, r, ok);
  ok' := true;
  r' := s;
}

lemma sp_lemma_whileTrue(b:obool, c:code, n:nat, s:state, r:state, ok:bool) returns(s':state, r':state, ok':bool)
  requires ValidState(s)
  requires ValidOperand(b.o1)
  requires ValidOperand(b.o2)
  requires n > 0
  requires evalWhileOpaque(b, c, n, s, r, ok)
  ensures  evalOBool(s, b)
  ensures  s' == s; // evalGuard
  ensures  sp_eval(c, s, r', ok')
  ensures  (if !ok' then !ok else evalWhileOpaque(b, c, n - 1, r', r, ok))
{
  reveal_sp_eval();
  reveal_evalWhileOpaque();
  s' := s;
  r', ok' :| evalOBool(s, b) && evalCode(c, s, r', ok') && (if !ok' then !ok else evalWhile(b, c, n - 1, r', r, ok));
}

lemma sp_lemma_whileFalse(b:obool, c:code, s:state, r:state, ok:bool)
  requires ValidState(s)
  requires ValidOperand(b.o1)
  requires ValidOperand(b.o2)
  requires evalWhileOpaque(b, c, 0, s, r, ok)
  ensures  !evalOBool(s, b)
  ensures  ok
  ensures  r == s
{
  reveal_sp_eval();
  reveal_evalWhileOpaque();
}

function ConcatenateCodes(code1:codes, code2:codes) : codes
{
    if code1.CNil? then
        code2
    else
        sp_CCons(code1.hd, ConcatenateCodes(code1.tl, code2))
}

lemma lemma_GetIntermediateStateBetweenCodeBlocks(s1:sp_state, s3:sp_state, code1:codes, code2:codes, codes1and2:codes, ok1and2:bool)
    returns (s2:sp_state, ok:bool)
    requires evalBlock(codes1and2, s1, s3, ok1and2);
    requires ConcatenateCodes(code1, code2) == codes1and2;
    ensures  evalBlock(code1, s1, s2, ok);
    ensures  if ok then evalBlock(code2, s2, s3, ok1and2) else !ok1and2;
    decreases code1;
{
    if code1.CNil? {
        s2 := s1;
        ok := true;
        return;
    }

    var s_mid, ok_mid :| evalCode(codes1and2.hd, s1, s_mid, ok_mid) && (if !ok_mid then !ok1and2 else evalBlock(codes1and2.tl, s_mid, s3, ok1and2));
    if ok_mid {
        s2, ok := lemma_GetIntermediateStateBetweenCodeBlocks(s_mid, s3, code1.tl, code2, codes1and2.tl, ok1and2);
    }
    else {
        ok := false;
    }
}
