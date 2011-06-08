# Run all tests in the current directory
# 
# Tests are run in a sub-interpreter (if possible) to avoid
# interactions between tests.

lappend auto_path .

if {[info commands interp] eq ""} {
	# poor-man's interp
	proc interp {} {
		# Save a list of the current global variables
		set globals [info globals]
		proc interp1 {cmd args} {globals} {
			if {$cmd eq "eval"} {
				uplevel #0 [concat $cmd $args]
			} elseif {$cmd eq "delete"} {
				# unset all globals we don't know about
				foreach p [info globals] {
					if {$p ni $globals} {
						unset -nocomplain ::$p
					}
				}
			}
		}
	}
}

proc runalltests {} {
	array set total {pass 0 fail 0 skip 0 tests 0}
	foreach script [lsort [glob *.test]] {
		set ::argv0 $script

		set i [interp]

		foreach var {argv0 auto_path} {
			$i eval [list set $var [set ::$var]]
		}

		# Run the test
		catch -exit {$i eval source $script} msg opts
		if {[info returncode $opts(-code)] eq "error"} {
			puts [format "%16s:   --- error ($msg)" $script]
			incr total(fail)
		}

		# Extract the counts
		foreach var {pass fail skip tests} {
			incr total($var) [$i eval "set testinfo(num$var)"]
		}

		$i delete
	}
	puts [string repeat = 73]
	puts [format "%16s: Total %5d   Passed %5d  Skipped %5d  Failed %5d" \
			Totals $total(tests) $total(pass) $total(skip) $total(fail)]
	return $total(fail)
}

if {[runalltests]} {
	exit 1
}
