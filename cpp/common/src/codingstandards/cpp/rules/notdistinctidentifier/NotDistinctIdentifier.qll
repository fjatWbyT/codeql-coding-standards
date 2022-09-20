/**
 * Provides a library which includes a `problems` predicate for reporting....
 */

import cpp
import codingstandards.cpp.Customizations
import codingstandards.cpp.Exclusions

abstract class NotDistinctIdentifierSharedQuery extends Query { }

Query getQuery() { result instanceof NotDistinctIdentifierSharedQuery }

query predicate problems(Element e, string message) {
not isExcluded(e, getQuery()) and message = "<replace with problem alert message for >"
}