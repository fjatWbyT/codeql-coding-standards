/**
 * A module for modeling types and functions declared in the `<random>` standard library header.
 */

import cpp

/**
 * A type which is a random number engine.
 */
abstract class RandomNumberEngine extends UserType { }

/**
 * A random number engine as specified in `[rand.eng]` and `[rand.adapt]`.
 */
class StdRandomNumberEngine extends RandomNumberEngine {
  StdRandomNumberEngine() {
    hasQualifiedName("std",
      [
        "linear_congruential_engine", "mersenne_twister_engine", "subtract_with_carry_engine",
        "discard_block_engine", "independent_bits_engine", "shuffle_order_engine"
      ])
  }
}

private newtype TRandomNumberEngineCreation =
  TRandomNumberEngineConstructorCall(ConstructorCall cc) {
    cc.getTarget().getDeclaringType() instanceof RandomNumberEngine
  } or
  TRandomNumberEngineMemberVariableDefaultInit(MemberVariable mv, Constructor c) {
    c.getDeclaringType() = mv.getDeclaringType() and
    mv.getType().getUnspecifiedType() instanceof RandomNumberEngine and
    c.getNumberOfParameters() = 0 and
    c.isCompilerGenerated()
  }

/**
 * A place in the program where a random number engine is created.
 */
class RandomNumberEngineCreation extends TRandomNumberEngineCreation {
  Element getExclusionElement() { none() }

  Location getLocation() { none() }

  int getNumberOfArguments() { none() }

  Expr getSeedArgument() { none() }

  RandomNumberEngine getCreatedRandomNumberEngine() { none() }

  string toString() { result = "RandomNumberEngineCreation" }
}

/**
 * A `ConstructorCall` which targets a `RandomNumberEngine`.
 */
class RandomNumberEngineConstructorCall extends TRandomNumberEngineConstructorCall,
  RandomNumberEngineCreation
{
  ConstructorCall getConstructorCall() { this = TRandomNumberEngineConstructorCall(result) }

  override Element getExclusionElement() { result = getConstructorCall() }

  override Location getLocation() { result = getConstructorCall().getLocation() }

  override int getNumberOfArguments() { result = getConstructorCall().getNumberOfArguments() }

  override Expr getSeedArgument() { result = getConstructorCall().getArgument(0) }

  override RandomNumberEngine getCreatedRandomNumberEngine() {
    result = getConstructorCall().getTarget().getDeclaringType()
  }

  override string toString() { result = getConstructorCall().toString() }
}

/**
 * The default initialization of a member variable of type `RandomNumberEngine`.
 *
 * This specifically covers the case where:
 *  - An implict default constructor is generated by the compiler
 *  - There is a member variable of type `RandomNumberEngine`.
 *
 * This is because no `ConstructorCall`s are generated in this case.
 */
class RandomNumberEngineMemberVariableDefaultInit extends TRandomNumberEngineMemberVariableDefaultInit,
  RandomNumberEngineCreation
{
  MemberVariable getMemberVariable() {
    this = TRandomNumberEngineMemberVariableDefaultInit(result, _)
  }

  Constructor getConstructor() { this = TRandomNumberEngineMemberVariableDefaultInit(_, result) }

  override Element getExclusionElement() { result = getMemberVariable() }

  override Location getLocation() { result = getMemberVariable().getLocation() }

  override int getNumberOfArguments() { result = 0 }

  override Expr getSeedArgument() { none() }

  override RandomNumberEngine getCreatedRandomNumberEngine() {
    result = getMemberVariable().getType().getUnspecifiedType()
  }

  override string toString() {
    result =
      "default initialization " + getMemberVariable().getName() + " of type " +
        getMemberVariable().getType().getName()
  }
}
