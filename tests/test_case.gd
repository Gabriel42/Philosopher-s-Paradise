class_name TestCase
extends Node
## Base class of the automated tests. A test file is tests/**/test_*.gd that
## extends TestCase; every method whose name starts with "test_" is one test.
## The runner (tests/run_tests.tscn) adds the file as a node, then for each
## test calls before_each(), the test, after_each().
## A test fails if an assert fails or an error is printed while it runs.

## Failure messages of the test running now (read by the runner).
var failures: Array[String] = []
## Nodes made by the test, freed after it (see [method keep]).
var _made: Array[Node] = []


## Runs before each test. Override to set things up.
func before_each() -> void:
	pass


## Runs after each test. Override to clean up.
func after_each() -> void:
	pass


# --- Asserts --------------------------------------------------------------------

func fail(message: String) -> void:
	failures.append(message)


func assert_true(condition: bool, message := "") -> void:
	if not condition:
		fail(_join("expected true", message))


func assert_false(condition: bool, message := "") -> void:
	if condition:
		fail(_join("expected false", message))


## Fails unless [param actual] == [param expected] (and both have the same type).
func assert_eq(actual: Variant, expected: Variant, message := "") -> void:
	if typeof(actual) != typeof(expected) or actual != expected:
		fail(_join("expected %s, got %s" % [var_to_str(expected), var_to_str(actual)], message))


func assert_ne(actual: Variant, unexpected: Variant, message := "") -> void:
	if typeof(actual) == typeof(unexpected) and actual == unexpected:
		fail(_join("expected anything but %s" % var_to_str(unexpected), message))


## Fails unless [param low] <= [param value] <= [param high].
func assert_between(value: Variant, low: Variant, high: Variant, message := "") -> void:
	if value < low or value > high:
		fail(_join("expected %s..%s, got %s" % [low, high, value], message))


## Fails unless [param actual] is within [param tolerance] of [param expected]
## (floats and vectors: physics numbers are never exact).
func assert_near(actual: Variant, expected: Variant, tolerance := 0.001, message := "") -> void:
	if actual is float or actual is int:
		if absf(actual - expected) > tolerance:
			fail(_join("expected %s ± %s, got %s" % [expected, tolerance, actual], message))
	elif actual.distance_to(expected) > tolerance:
		fail(_join("expected %s ± %s, got %s" % [expected, tolerance, actual], message))


# --- Helpers --------------------------------------------------------------------

## Adds [param node] to the tree under this test and frees it when the test ends.
func keep(node: Node) -> Node:
	add_child(node)
	_made.append(node)
	return node


## Frees what the test made. Called by the runner after after_each().
func clean_up() -> void:
	for node in _made:
		if is_instance_valid(node):
			node.free()
	_made.clear()


func _join(what: String, message: String) -> String:
	return what if message == "" else "%s: %s" % [message, what]
