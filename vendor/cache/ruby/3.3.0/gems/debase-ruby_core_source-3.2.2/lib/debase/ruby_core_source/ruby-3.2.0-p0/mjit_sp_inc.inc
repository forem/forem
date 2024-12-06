static rb_snum_t
mjit_call_attribute_sp_inc(const int insn, const VALUE *operands)
{
    switch (insn) {
      case BIN(nop): {
        return attr_sp_inc_nop();
      }
      case BIN(getlocal): {
        MAYBE_UNUSED(lindex_t idx) = (lindex_t)operands[0];
        MAYBE_UNUSED(rb_num_t level) = (rb_num_t)operands[1];
        return attr_sp_inc_getlocal(idx, level);
      }
      case BIN(setlocal): {
        MAYBE_UNUSED(lindex_t idx) = (lindex_t)operands[0];
        MAYBE_UNUSED(rb_num_t level) = (rb_num_t)operands[1];
        return attr_sp_inc_setlocal(idx, level);
      }
      case BIN(getblockparam): {
        MAYBE_UNUSED(lindex_t idx) = (lindex_t)operands[0];
        MAYBE_UNUSED(rb_num_t level) = (rb_num_t)operands[1];
        return attr_sp_inc_getblockparam(idx, level);
      }
      case BIN(setblockparam): {
        MAYBE_UNUSED(lindex_t idx) = (lindex_t)operands[0];
        MAYBE_UNUSED(rb_num_t level) = (rb_num_t)operands[1];
        return attr_sp_inc_setblockparam(idx, level);
      }
      case BIN(getblockparamproxy): {
        MAYBE_UNUSED(lindex_t idx) = (lindex_t)operands[0];
        MAYBE_UNUSED(rb_num_t level) = (rb_num_t)operands[1];
        return attr_sp_inc_getblockparamproxy(idx, level);
      }
      case BIN(getspecial): {
        MAYBE_UNUSED(rb_num_t key) = (rb_num_t)operands[0];
        MAYBE_UNUSED(rb_num_t type) = (rb_num_t)operands[1];
        return attr_sp_inc_getspecial(key, type);
      }
      case BIN(setspecial): {
        MAYBE_UNUSED(rb_num_t key) = (rb_num_t)operands[0];
        return attr_sp_inc_setspecial(key);
      }
      case BIN(getinstancevariable): {
        MAYBE_UNUSED(ID id) = (ID)operands[0];
        MAYBE_UNUSED(IVC ic) = (IVC)operands[1];
        return attr_sp_inc_getinstancevariable(id, ic);
      }
      case BIN(setinstancevariable): {
        MAYBE_UNUSED(ID id) = (ID)operands[0];
        MAYBE_UNUSED(IVC ic) = (IVC)operands[1];
        return attr_sp_inc_setinstancevariable(id, ic);
      }
      case BIN(getclassvariable): {
        MAYBE_UNUSED(ID id) = (ID)operands[0];
        MAYBE_UNUSED(ICVARC ic) = (ICVARC)operands[1];
        return attr_sp_inc_getclassvariable(id, ic);
      }
      case BIN(setclassvariable): {
        MAYBE_UNUSED(ID id) = (ID)operands[0];
        MAYBE_UNUSED(ICVARC ic) = (ICVARC)operands[1];
        return attr_sp_inc_setclassvariable(id, ic);
      }
      case BIN(opt_getconstant_path): {
        MAYBE_UNUSED(IC ic) = (IC)operands[0];
        return attr_sp_inc_opt_getconstant_path(ic);
      }
      case BIN(getconstant): {
        MAYBE_UNUSED(ID id) = (ID)operands[0];
        return attr_sp_inc_getconstant(id);
      }
      case BIN(setconstant): {
        MAYBE_UNUSED(ID id) = (ID)operands[0];
        return attr_sp_inc_setconstant(id);
      }
      case BIN(getglobal): {
        MAYBE_UNUSED(ID gid) = (ID)operands[0];
        return attr_sp_inc_getglobal(gid);
      }
      case BIN(setglobal): {
        MAYBE_UNUSED(ID gid) = (ID)operands[0];
        return attr_sp_inc_setglobal(gid);
      }
      case BIN(putnil): {
        return attr_sp_inc_putnil();
      }
      case BIN(putself): {
        return attr_sp_inc_putself();
      }
      case BIN(putobject): {
        MAYBE_UNUSED(VALUE val) = (VALUE)operands[0];
        return attr_sp_inc_putobject(val);
      }
      case BIN(putspecialobject): {
        MAYBE_UNUSED(rb_num_t value_type) = (rb_num_t)operands[0];
        return attr_sp_inc_putspecialobject(value_type);
      }
      case BIN(putstring): {
        MAYBE_UNUSED(VALUE str) = (VALUE)operands[0];
        return attr_sp_inc_putstring(str);
      }
      case BIN(concatstrings): {
        MAYBE_UNUSED(rb_num_t num) = (rb_num_t)operands[0];
        return attr_sp_inc_concatstrings(num);
      }
      case BIN(anytostring): {
        return attr_sp_inc_anytostring();
      }
      case BIN(toregexp): {
        MAYBE_UNUSED(rb_num_t opt) = (rb_num_t)operands[0];
        MAYBE_UNUSED(rb_num_t cnt) = (rb_num_t)operands[1];
        return attr_sp_inc_toregexp(opt, cnt);
      }
      case BIN(intern): {
        return attr_sp_inc_intern();
      }
      case BIN(newarray): {
        MAYBE_UNUSED(rb_num_t num) = (rb_num_t)operands[0];
        return attr_sp_inc_newarray(num);
      }
      case BIN(newarraykwsplat): {
        MAYBE_UNUSED(rb_num_t num) = (rb_num_t)operands[0];
        return attr_sp_inc_newarraykwsplat(num);
      }
      case BIN(duparray): {
        MAYBE_UNUSED(VALUE ary) = (VALUE)operands[0];
        return attr_sp_inc_duparray(ary);
      }
      case BIN(duphash): {
        MAYBE_UNUSED(VALUE hash) = (VALUE)operands[0];
        return attr_sp_inc_duphash(hash);
      }
      case BIN(expandarray): {
        MAYBE_UNUSED(rb_num_t num) = (rb_num_t)operands[0];
        MAYBE_UNUSED(rb_num_t flag) = (rb_num_t)operands[1];
        return attr_sp_inc_expandarray(num, flag);
      }
      case BIN(concatarray): {
        return attr_sp_inc_concatarray();
      }
      case BIN(splatarray): {
        MAYBE_UNUSED(VALUE flag) = (VALUE)operands[0];
        return attr_sp_inc_splatarray(flag);
      }
      case BIN(newhash): {
        MAYBE_UNUSED(rb_num_t num) = (rb_num_t)operands[0];
        return attr_sp_inc_newhash(num);
      }
      case BIN(newrange): {
        MAYBE_UNUSED(rb_num_t flag) = (rb_num_t)operands[0];
        return attr_sp_inc_newrange(flag);
      }
      case BIN(pop): {
        return attr_sp_inc_pop();
      }
      case BIN(dup): {
        return attr_sp_inc_dup();
      }
      case BIN(dupn): {
        MAYBE_UNUSED(rb_num_t n) = (rb_num_t)operands[0];
        return attr_sp_inc_dupn(n);
      }
      case BIN(swap): {
        return attr_sp_inc_swap();
      }
      case BIN(opt_reverse): {
        MAYBE_UNUSED(rb_num_t n) = (rb_num_t)operands[0];
        return attr_sp_inc_opt_reverse(n);
      }
      case BIN(topn): {
        MAYBE_UNUSED(rb_num_t n) = (rb_num_t)operands[0];
        return attr_sp_inc_topn(n);
      }
      case BIN(setn): {
        MAYBE_UNUSED(rb_num_t n) = (rb_num_t)operands[0];
        return attr_sp_inc_setn(n);
      }
      case BIN(adjuststack): {
        MAYBE_UNUSED(rb_num_t n) = (rb_num_t)operands[0];
        return attr_sp_inc_adjuststack(n);
      }
      case BIN(defined): {
        MAYBE_UNUSED(rb_num_t op_type) = (rb_num_t)operands[0];
        MAYBE_UNUSED(VALUE obj) = (VALUE)operands[1];
        MAYBE_UNUSED(VALUE pushval) = (VALUE)operands[2];
        return attr_sp_inc_defined(op_type, obj, pushval);
      }
      case BIN(checkmatch): {
        MAYBE_UNUSED(rb_num_t flag) = (rb_num_t)operands[0];
        return attr_sp_inc_checkmatch(flag);
      }
      case BIN(checkkeyword): {
        MAYBE_UNUSED(lindex_t kw_bits_index) = (lindex_t)operands[0];
        MAYBE_UNUSED(lindex_t keyword_index) = (lindex_t)operands[1];
        return attr_sp_inc_checkkeyword(kw_bits_index, keyword_index);
      }
      case BIN(checktype): {
        MAYBE_UNUSED(rb_num_t type) = (rb_num_t)operands[0];
        return attr_sp_inc_checktype(type);
      }
      case BIN(defineclass): {
        MAYBE_UNUSED(ID id) = (ID)operands[0];
        MAYBE_UNUSED(ISEQ class_iseq) = (ISEQ)operands[1];
        MAYBE_UNUSED(rb_num_t flags) = (rb_num_t)operands[2];
        return attr_sp_inc_defineclass(id, class_iseq, flags);
      }
      case BIN(definemethod): {
        MAYBE_UNUSED(ID id) = (ID)operands[0];
        MAYBE_UNUSED(ISEQ iseq) = (ISEQ)operands[1];
        return attr_sp_inc_definemethod(id, iseq);
      }
      case BIN(definesmethod): {
        MAYBE_UNUSED(ID id) = (ID)operands[0];
        MAYBE_UNUSED(ISEQ iseq) = (ISEQ)operands[1];
        return attr_sp_inc_definesmethod(id, iseq);
      }
      case BIN(send): {
        MAYBE_UNUSED(CALL_DATA cd) = (CALL_DATA)operands[0];
        MAYBE_UNUSED(ISEQ blockiseq) = (ISEQ)operands[1];
        return attr_sp_inc_send(cd, blockiseq);
      }
      case BIN(opt_send_without_block): {
        MAYBE_UNUSED(CALL_DATA cd) = (CALL_DATA)operands[0];
        return attr_sp_inc_opt_send_without_block(cd);
      }
      case BIN(objtostring): {
        MAYBE_UNUSED(CALL_DATA cd) = (CALL_DATA)operands[0];
        return attr_sp_inc_objtostring(cd);
      }
      case BIN(opt_str_freeze): {
        MAYBE_UNUSED(VALUE str) = (VALUE)operands[0];
        MAYBE_UNUSED(CALL_DATA cd) = (CALL_DATA)operands[1];
        return attr_sp_inc_opt_str_freeze(str, cd);
      }
      case BIN(opt_nil_p): {
        MAYBE_UNUSED(CALL_DATA cd) = (CALL_DATA)operands[0];
        return attr_sp_inc_opt_nil_p(cd);
      }
      case BIN(opt_str_uminus): {
        MAYBE_UNUSED(VALUE str) = (VALUE)operands[0];
        MAYBE_UNUSED(CALL_DATA cd) = (CALL_DATA)operands[1];
        return attr_sp_inc_opt_str_uminus(str, cd);
      }
      case BIN(opt_newarray_max): {
        MAYBE_UNUSED(rb_num_t num) = (rb_num_t)operands[0];
        return attr_sp_inc_opt_newarray_max(num);
      }
      case BIN(opt_newarray_min): {
        MAYBE_UNUSED(rb_num_t num) = (rb_num_t)operands[0];
        return attr_sp_inc_opt_newarray_min(num);
      }
      case BIN(invokesuper): {
        MAYBE_UNUSED(CALL_DATA cd) = (CALL_DATA)operands[0];
        MAYBE_UNUSED(ISEQ blockiseq) = (ISEQ)operands[1];
        return attr_sp_inc_invokesuper(cd, blockiseq);
      }
      case BIN(invokeblock): {
        MAYBE_UNUSED(CALL_DATA cd) = (CALL_DATA)operands[0];
        return attr_sp_inc_invokeblock(cd);
      }
      case BIN(leave): {
        return attr_sp_inc_leave();
      }
      case BIN(throw): {
        MAYBE_UNUSED(rb_num_t throw_state) = (rb_num_t)operands[0];
        return attr_sp_inc_throw(throw_state);
      }
      case BIN(jump): {
        MAYBE_UNUSED(OFFSET dst) = (OFFSET)operands[0];
        return attr_sp_inc_jump(dst);
      }
      case BIN(branchif): {
        MAYBE_UNUSED(OFFSET dst) = (OFFSET)operands[0];
        return attr_sp_inc_branchif(dst);
      }
      case BIN(branchunless): {
        MAYBE_UNUSED(OFFSET dst) = (OFFSET)operands[0];
        return attr_sp_inc_branchunless(dst);
      }
      case BIN(branchnil): {
        MAYBE_UNUSED(OFFSET dst) = (OFFSET)operands[0];
        return attr_sp_inc_branchnil(dst);
      }
      case BIN(once): {
        MAYBE_UNUSED(ISEQ iseq) = (ISEQ)operands[0];
        MAYBE_UNUSED(ISE ise) = (ISE)operands[1];
        return attr_sp_inc_once(iseq, ise);
      }
      case BIN(opt_case_dispatch): {
        MAYBE_UNUSED(CDHASH hash) = (CDHASH)operands[0];
        MAYBE_UNUSED(OFFSET else_offset) = (OFFSET)operands[1];
        return attr_sp_inc_opt_case_dispatch(hash, else_offset);
      }
      case BIN(opt_plus): {
        MAYBE_UNUSED(CALL_DATA cd) = (CALL_DATA)operands[0];
        return attr_sp_inc_opt_plus(cd);
      }
      case BIN(opt_minus): {
        MAYBE_UNUSED(CALL_DATA cd) = (CALL_DATA)operands[0];
        return attr_sp_inc_opt_minus(cd);
      }
      case BIN(opt_mult): {
        MAYBE_UNUSED(CALL_DATA cd) = (CALL_DATA)operands[0];
        return attr_sp_inc_opt_mult(cd);
      }
      case BIN(opt_div): {
        MAYBE_UNUSED(CALL_DATA cd) = (CALL_DATA)operands[0];
        return attr_sp_inc_opt_div(cd);
      }
      case BIN(opt_mod): {
        MAYBE_UNUSED(CALL_DATA cd) = (CALL_DATA)operands[0];
        return attr_sp_inc_opt_mod(cd);
      }
      case BIN(opt_eq): {
        MAYBE_UNUSED(CALL_DATA cd) = (CALL_DATA)operands[0];
        return attr_sp_inc_opt_eq(cd);
      }
      case BIN(opt_neq): {
        MAYBE_UNUSED(CALL_DATA cd_eq) = (CALL_DATA)operands[0];
        MAYBE_UNUSED(CALL_DATA cd) = (CALL_DATA)operands[1];
        return attr_sp_inc_opt_neq(cd_eq, cd);
      }
      case BIN(opt_lt): {
        MAYBE_UNUSED(CALL_DATA cd) = (CALL_DATA)operands[0];
        return attr_sp_inc_opt_lt(cd);
      }
      case BIN(opt_le): {
        MAYBE_UNUSED(CALL_DATA cd) = (CALL_DATA)operands[0];
        return attr_sp_inc_opt_le(cd);
      }
      case BIN(opt_gt): {
        MAYBE_UNUSED(CALL_DATA cd) = (CALL_DATA)operands[0];
        return attr_sp_inc_opt_gt(cd);
      }
      case BIN(opt_ge): {
        MAYBE_UNUSED(CALL_DATA cd) = (CALL_DATA)operands[0];
        return attr_sp_inc_opt_ge(cd);
      }
      case BIN(opt_ltlt): {
        MAYBE_UNUSED(CALL_DATA cd) = (CALL_DATA)operands[0];
        return attr_sp_inc_opt_ltlt(cd);
      }
      case BIN(opt_and): {
        MAYBE_UNUSED(CALL_DATA cd) = (CALL_DATA)operands[0];
        return attr_sp_inc_opt_and(cd);
      }
      case BIN(opt_or): {
        MAYBE_UNUSED(CALL_DATA cd) = (CALL_DATA)operands[0];
        return attr_sp_inc_opt_or(cd);
      }
      case BIN(opt_aref): {
        MAYBE_UNUSED(CALL_DATA cd) = (CALL_DATA)operands[0];
        return attr_sp_inc_opt_aref(cd);
      }
      case BIN(opt_aset): {
        MAYBE_UNUSED(CALL_DATA cd) = (CALL_DATA)operands[0];
        return attr_sp_inc_opt_aset(cd);
      }
      case BIN(opt_aset_with): {
        MAYBE_UNUSED(VALUE key) = (VALUE)operands[0];
        MAYBE_UNUSED(CALL_DATA cd) = (CALL_DATA)operands[1];
        return attr_sp_inc_opt_aset_with(key, cd);
      }
      case BIN(opt_aref_with): {
        MAYBE_UNUSED(VALUE key) = (VALUE)operands[0];
        MAYBE_UNUSED(CALL_DATA cd) = (CALL_DATA)operands[1];
        return attr_sp_inc_opt_aref_with(key, cd);
      }
      case BIN(opt_length): {
        MAYBE_UNUSED(CALL_DATA cd) = (CALL_DATA)operands[0];
        return attr_sp_inc_opt_length(cd);
      }
      case BIN(opt_size): {
        MAYBE_UNUSED(CALL_DATA cd) = (CALL_DATA)operands[0];
        return attr_sp_inc_opt_size(cd);
      }
      case BIN(opt_empty_p): {
        MAYBE_UNUSED(CALL_DATA cd) = (CALL_DATA)operands[0];
        return attr_sp_inc_opt_empty_p(cd);
      }
      case BIN(opt_succ): {
        MAYBE_UNUSED(CALL_DATA cd) = (CALL_DATA)operands[0];
        return attr_sp_inc_opt_succ(cd);
      }
      case BIN(opt_not): {
        MAYBE_UNUSED(CALL_DATA cd) = (CALL_DATA)operands[0];
        return attr_sp_inc_opt_not(cd);
      }
      case BIN(opt_regexpmatch2): {
        MAYBE_UNUSED(CALL_DATA cd) = (CALL_DATA)operands[0];
        return attr_sp_inc_opt_regexpmatch2(cd);
      }
      case BIN(invokebuiltin): {
        MAYBE_UNUSED(RB_BUILTIN bf) = (RB_BUILTIN)operands[0];
        return attr_sp_inc_invokebuiltin(bf);
      }
      case BIN(opt_invokebuiltin_delegate): {
        MAYBE_UNUSED(RB_BUILTIN bf) = (RB_BUILTIN)operands[0];
        MAYBE_UNUSED(rb_num_t index) = (rb_num_t)operands[1];
        return attr_sp_inc_opt_invokebuiltin_delegate(bf, index);
      }
      case BIN(opt_invokebuiltin_delegate_leave): {
        MAYBE_UNUSED(RB_BUILTIN bf) = (RB_BUILTIN)operands[0];
        MAYBE_UNUSED(rb_num_t index) = (rb_num_t)operands[1];
        return attr_sp_inc_opt_invokebuiltin_delegate_leave(bf, index);
      }
      case BIN(getlocal_WC_0): {
        MAYBE_UNUSED(lindex_t idx) = (lindex_t)operands[0];
        return attr_sp_inc_getlocal_WC_0(idx);
      }
      case BIN(getlocal_WC_1): {
        MAYBE_UNUSED(lindex_t idx) = (lindex_t)operands[0];
        return attr_sp_inc_getlocal_WC_1(idx);
      }
      case BIN(setlocal_WC_0): {
        MAYBE_UNUSED(lindex_t idx) = (lindex_t)operands[0];
        return attr_sp_inc_setlocal_WC_0(idx);
      }
      case BIN(setlocal_WC_1): {
        MAYBE_UNUSED(lindex_t idx) = (lindex_t)operands[0];
        return attr_sp_inc_setlocal_WC_1(idx);
      }
      case BIN(putobject_INT2FIX_0_): {
        return attr_sp_inc_putobject_INT2FIX_0_();
      }
      case BIN(putobject_INT2FIX_1_): {
        return attr_sp_inc_putobject_INT2FIX_1_();
      }
      default:
        rb_bug("unexpected insn in mjit_call_attribute_sp_inc");
    }
}
