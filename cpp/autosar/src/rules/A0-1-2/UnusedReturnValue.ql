/**
 * @id cpp/autosar/unused-return-value
 * @name A0-1-2: Unused return value
 * @description The value returned by a function having a non-void return type that is not an
 *              overloaded operator shall be used.
 * @kind problem
 * @precision very-high
 * @problem.severity warning
 * @tags external/autosar/id/a0-1-2
 *       readability
 *       maintainability
 *       external/autosar/allocated-target/implementation
 *       external/autosar/enforcement/automated
 *       external/autosar/obligation/required
 */

import cpp
import codingstandards.cpp.autosar
import semmle.code.cpp.dataflow.DataFlow

predicate isStdIgnore(Element element) {
  exists(NameQualifier nq |
    nq.getQualifiedElement().toString() = "ignore" and
    nq.toString() = "std::" and
    element.toString() = "ignore"
  )
}

/* The statement std::ignore = f() is not recognized an assignment; therefore, we do some painful acrobatics. */
predicate isAssignment(FunctionCall assignment) {
  exists(Operator operator |
    assignment.getTarget() = operator and
    operator.getName() = "operator=" and
    // check if this is indeed an operator for assignment by checking if there are no overloads
    not exists(operator.getAnOverload())
  )
}

predicate isAssignmentOperand(Expr operand) {
  exists(FunctionCall assignment | isAssignment(assignment) and operand = assignment.getAChild())
}

predicate returnValueIsAssignedToStdIgnore(FunctionCall fc) {
  isAssignmentOperand(fc) and exists(Element stdIgnore | isStdIgnore(stdIgnore))
}

/*
 * This query performs a simple syntactic check to ensure that the return value of the function is
 * not completely ignored. This matches the examples given in the rule, although the text itself is
 * not entirely clear. This means it will not find cases where something is done with the return
 * value, but it is not meaningfully read. For example: `int ret_val = f();`, with no subsequent
 * access of `ret_val`. However, such a case _would_ be flagged by A0-1-1 - Useless assignment.
 */

from FunctionCall fc, Function f
where
  not isExcluded(fc, DeadCodePackage::unusedReturnValueQuery()) and
  // Find function calls in `ExprStmt`s, which indicate the return value is ignored
  fc.getParent() instanceof ExprStmt and
  // Ignore calls to void functions, which don't return values
  not fc.getUnderlyingType() instanceof VoidType and
  // Get the function target
  f = fc.getTarget() and
  // Overloaded (i.e. user defined) operators should behave in the same way as built-in operators,
  // so the rule does not require the use of the return value
  not f instanceof Operator and
  // Exclude cases where the function call is generated within a macro, as the user of the macro is
  // not necessarily able to address those results
  not fc.isAffectedByMacro() and
  // Rule allows disabling this rule where a static_cast<void> or a C-style cast to void is applied
  not (
    fc.getExplicitlyConverted().(StaticCast).getActualType() instanceof VoidType
    or
    exists(CStyleCast cast |
      not cast.isCompilerGenerated() and
      cast.getExpr() = fc
    )
  ) and
  not returnValueIsAssignedToStdIgnore(fc)
select fc, "Return value from call to $@ is unused.", f, f.getName()
