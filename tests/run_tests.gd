extends Node
## Runs every test in tests/ (files named test_*.gd extending [TestCase]),
## prints the results and quits: exit code 0 if all passed, 1 otherwise.
##
## Run all:      Godot --headless --path . res://tests/run_tests.tscn
## Run some:     add  -- --only=board  (files whose name contains "board")
## Always in English (the OS language would change the texts the tests read).

const TESTS_DIR := "res://tests"
## Problems printed per failed test (the rest are counted).
const MAX_PROBLEMS_SHOWN := 5


## Catches errors printed while a test runs, so they make it fail.
class ErrorCatcher extends Logger:
	var errors: Array[String] = []

	func _log_error(function: String, file: String, line: int, code: String,
			rationale: String, _editor_notify: bool, error_type: int,
			_script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_WARNING:
			return
		var text := rationale if rationale != "" else code
		errors.append("error: %s (%s:%d in %s)" % [text, file.get_file(), line, function])


func _ready() -> void:
	var only := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):
			only = arg.trim_prefix("--only=")

	# The tests read English texts, whatever the OS language.
	TranslationServer.set_locale("en")
	_start_watchdog()
	var catcher := ErrorCatcher.new()
	OS.add_logger(catcher)
	var passed := 0
	var failed: Array[String] = []
	var start := Time.get_ticks_msec()

	for path in _test_files(TESTS_DIR):
		if only != "" and not path.get_file().contains(only):
			continue
		_watchdog_at(path)
		var script := load(path) as GDScript
		# A script with a parse error can't be instantiated: calling new() on it
		# stops this function, and the runner would never quit.
		var ok := script != null and script.can_instantiate()
		var case := script.new() as TestCase if ok else null
		if case == null:
			failed.append(path)
			print("FAIL  %s: can't load it, or it doesn't extend TestCase" % path)
			continue
		add_child(case)
		print("%s" % path.trim_prefix(TESTS_DIR + "/"))
		for method in script.get_script_method_list():
			var test_name: String = method.name
			if not test_name.begins_with("test_"):
				continue
			_watchdog_at("%s: %s" % [path.get_file(), test_name])
			case.failures.clear()
			catcher.errors.clear()
			case.before_each()
			await case.call(test_name)
			case.after_each()
			case.clean_up()
			var problems: Array[String] = case.failures + catcher.errors
			if problems.is_empty():
				passed += 1
				print("  ok    %s" % test_name)
			else:
				failed.append("%s: %s" % [path.get_file(), test_name])
				print("  FAIL  %s" % test_name)
				for problem in problems.slice(0, MAX_PROBLEMS_SHOWN):
					print("        %s" % problem)
				if problems.size() > MAX_PROBLEMS_SHOWN:
					print("        ... and %d more" % (problems.size() - MAX_PROBLEMS_SHOWN))
		case.free()

	OS.remove_logger(catcher)
	print("")
	print("%d passed, %d failed (%d ms)" % [passed, failed.size(), Time.get_ticks_msec() - start])
	for name in failed:
		print("  failed: %s" % name)
	get_tree().quit(0 if failed.is_empty() and passed > 0 else 1)


## The watchdog: if one test (or loading one file) takes longer than this, the
## runner prints where it's stuck and quits with exit code 1, instead of
## hanging forever (a script error inside the loop, or an await that never ends).
const STUCK_SECONDS := 60.0

var _watchdog_where := "starting"
var _watchdog_since := 0


func _start_watchdog() -> void:
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.timeout.connect(_check_watchdog)
	add_child(timer)
	timer.start()
	_watchdog_at("starting")


## Marks what the runner is doing now (shown if it gets stuck there).
func _watchdog_at(where: String) -> void:
	_watchdog_where = where
	_watchdog_since = Time.get_ticks_msec()


func _check_watchdog() -> void:
	if Time.get_ticks_msec() - _watchdog_since > STUCK_SECONDS * 1000.0:
		print("")
		print("STUCK  %s: nothing finished for %d s, stopping the tests." % [
				_watchdog_where, int(STUCK_SECONDS)])
		get_tree().quit(1)


## Every test_*.gd under [param dir], sorted.
func _test_files(dir: String) -> Array[String]:
	var result: Array[String] = []
	for file in DirAccess.get_files_at(dir):
		if file.begins_with("test_") and file.ends_with(".gd") and file != "test_case.gd":
			result.append(dir.path_join(file))
	for sub in DirAccess.get_directories_at(dir):
		result.append_array(_test_files(dir.path_join(sub)))
	result.sort()
	return result
