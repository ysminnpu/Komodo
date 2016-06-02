include "ARMdef.dfy"

method cma()       { print(", "); }
method nl()        { print("\n"); }
method not_impl()  { print("  !!!NOT IMPLEMENTED!!!"); }

function method cmpNot(c:ocmp):ocmp
{
  match c
    case OEq => ONe
    case ONe => OEq
    case OLe => OGt
    case OGe => OLt
    case OLt => OGe
    case OGt => OLe
}

method printBcc(c:ocmp)
{
	match c
	{
		case OEq => print("B EQ");
		case ONe => print("B NE ");
		case OLe => print("B LE ");
		case OGe => print("B GE ");
		case OLt => print("B LT ");
		case OGt => print("B GT ");
	}
}

method printId(id:id)
{
	match id
	{
		case IdARMReg(r) => { match r
			case R(i) => print("r"); print(i); }
    	case IdGlobal(g) => print(" !!!NOT IMPLEMENTED!!!");
    	case IdLocal(l) => print(" !!!NOT IMPLEMENTED!!!");
    	case IdStackSlot(i) => print(" !!! NOT IMPLEMENTED!!!");
	}
}

method printOperand(o:operand)
{
  match o
  {
    case OConst(n) =>
    {
      if 0 <= n < 0x1_0000_0000 { print(n); }
      else { print(" !!!NOT IMPLEMENTED!!!"); }
    }
    case OVar(x) => printId(x);
    case OHeap(addr) => print(" !!!NOT IMPLEMENTED!!!");
  }
}

method printIns(ins:ins)
{
	match ins
	{
		case ADD(dest, src1, src2) =>
			print("  Add"); printOperand(dest); cma();
				printOperand(src1); cma();
				printOperand(src2); nl();
	}
}

method printBlock(b:codes, n:int) returns(n':int)
{
  n' := n;
  var i := b;
  while (i.sp_CCons?)
    decreases i
  {
    n' := printCode(i.hd, n');
    i := i.tl;
  }
}

method printCode(c:code, n:int) returns(n':int)
{
	match c
	{
		case Ins(ins) => printIns(ins); n':= n;
    	case Block(block) => n' := printBlock(block, n);
		case IfElse(ifb, ift, iff) => {
			var false_branch := n;
			var end_of_block := n + 1;
			// Do comparison
			print("  cmp "); printOperand(ifb.o1); cma();
				printOperand(ifb.o2); nl();
			// Branch to false branch if cond is false
			printBcc(cmpNot(ifb.cmp)); print("L"); print(false_branch); nl();
			// True branch
      		n' := printCode(ift, n + 2);
      		print("  B L"); print(end_of_block); nl(); 
      		print("L"); print(false_branch); print(":\n");
			// False branch
      		n' := printCode(iff, n');
			// Label end of block
      		print("L"); print(end_of_block); print(":\n");
		}	
    	case While(b, loop) =>
    	{
    	  var n1 := n;
    	  var n2 := n + 1;
    	  print("  B L"); print(n2); print("\n");
    	  print("L"); print(n1); print(":\n");
    	  n' := printCode(loop, n + 2);
    	  print("L"); print(n2); print(":\n");
    	  print("  cmp "); printOperand(b.o1); print(", "); printOperand(b.o2); print("\n");
    	  printBcc(cmpNot(b.cmp)); print("L"); print(n1); print("\n");
    	}
	}
}