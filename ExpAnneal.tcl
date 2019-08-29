canvas .c -background white -width 900 -height 500
ttk::progressbar .p1
ttk::progressbar .p2 -length 110

button .b1 -width 15 -text "Generation" -command {generation $NofGenerations}
button .b2 -width 15 -text "precGeneration" -command {precgeneration $NofprecGenerations}
button .b3 -width 15 -text "unnoise" -command {unnoising}
button .b4 -width 15 -text "Anneal" -command {annealgeneration $NofannealGenerations}
button .b5 -width 15 -text "Exit" -command {exit}

entry .e1 -width 15 -textvariable NofGenerations
entry .e2 -width 15 -textvariable NofprecGenerations
entry .e3 -width 15 -textvariable minxi
entry .e4 -width 15 -textvariable NofannealGenerations

grid .e1 -column 1 -row 1 -sticky s
grid .b1 -column 1 -row 2 -sticky n
grid .e2 -column 1 -row 4 -sticky s
grid .b2 -column 1 -row 5 -sticky n
grid .e4 -column 1 -row 6 -sticky s
grid .b4 -column 1 -row 7 -sticky n
grid .e3 -column 1 -row 1 -sticky n
grid .b3 -column 1 -row 8
grid .b5 -column 1 -row 9
grid .p1 -column 2 -row 9 -sticky we
grid .p2 -column 1 -row 7 -sticky e
grid .c -column 2 -row 1 -rowspan 8

proc dot {x y} {
	.c create oval [expr $x*400+100-1] [expr 400-$y*200-1] [expr $x*400+100+1] [expr 400-$y*200+1]
}

proc littlecoldot {x y col} {
	.c create oval [expr log10($x)*100+900-2] [expr -$y*100+100-2] [expr log10($x)*100+900+2] [expr -$y*100+100+2] -fill #$col
}

set t1 0.1
set t2 0.8
set a1 0.5
set a2 -0.3
set coefa 0.05
set coefb 0.00
set a0 0
set b0 0
set mina0 0
set minb0 0
set Nofp 20
set taumin 0.01
set taumax 1
set tpoints 2000
set tmin 0.0
set tmax 2
set NofGenerations 100
set NofprecGenerations 100
set NofannealGenerations 1000
set signalampl 1
set flag_newminxi 0

array unset tlist
array unset alist
array unset minalist
array unset datasteps
array unset datalist
array unset stopsum

array unset exponents

proc generatetau {} {
	global tlist; global exponents; global stopsum; global datasteps
	global Nofp; global taumin; global taumax; global tpoints
	array unset exponents
	
	for {set i 0} {$i <= $Nofp} {incr i} {
		set tlist($i) [expr ($taumax/$taumin)**(double($i)/$Nofp-1)]
		set stopsum($i) $tpoints
		for {set j 0} {$j <= $tpoints} {incr j} {
			set exponents($j,$i) [expr exp(-$datasteps($j)/$tlist($i))]
			if {$exponents($j,$i) > [expr $exponents(0,$i)/1e6]} {set stopsum($i) $j}
		}
	}
}

proc generatedata {} {
	global datalist; global datasteps
	global a1; global a2; global coefa; global coefb; global t1; global t2; global minxi; global mina0; global minb0; global signalampl
	global tpoints; global tmin; global tmax
	
	for {set i 0} {$i <= $tpoints} {incr i} {
		set datasteps($i) [expr ($tmax-$tmin)*$i/$tpoints]
		
		comment {
		if {$i < 1000} {
			set datasteps($i) [expr ($tmax-$tmin)*$i/$tpoints/5]
		} else {
			set datasteps($i) [expr ($tmax-$tmin)*(($i-1000)*1.8+200)/$tpoints]
		}
		}
		
		set datalist($i) [expr $a1*exp(-$datasteps($i)/$t1)+$a2*exp(-$datasteps($i)/$t2)+$coefa+$coefb*$datasteps($i)]
	}
	
	set minsignal $datalist(0)
	set maxsignal $datalist(0)
	
	foreach i [array names datalist] {
		if {$minsignal < $datalist($i)} {set minsignal $datalist($i)}
		if {$maxsignal > $datalist($i)} {set minsignal $datalist($i)}
	}
	
	set signalampl [expr $maxsignal-$minsignal]
	
	set minxi [expr 2*$tpoints*$signalampl**2]
	
	set mina0 0
	set minb0 0
	
	generatetau
	renewplot
}

proc renewplot {} {
	global datasteps; global datalist
	global a1; global a2; global a3; global t1; global t2
	.c delete all
	.c create line 0 400 900 400
	.c create line 100 0 100 500

	for {set i 0} {$i < [array size datalist]} {incr i} {
		set x $datasteps($i)
		set y $datalist($i)
		dot $x $y
	}
	#dot [expr $t1-2] $a1
	#dot [expr $t2-2] $a2
	#dot 0 $a3
	
	.c create line 600 100 900 100
	.c create line 700 110 700 90
	.c create line 800 110 800 90
	littlecoldot $t1 $a1 "DD0000"
	littlecoldot $t2 $a2 "DD0000"
}

proc generatearray {} {
	global alist; global a0; global b0; global Nofp
	for {set i 0} {$i <= $Nofp} {incr i} {
		set alist($i) [expr (100000**(rand()-1))*((-1)**int(1000*rand()))]
	}
	set a0 [expr (rand()-0.5)]
	set b0 [expr (rand()-0.5)*100**(rand()-1)]
	set b0 0
}

proc precgeneratearray {} {
	global alist; global a0; global b0; global Nofp; global minalist; global mina0; global minb0
	for {set i 0} {$i <= $Nofp} {incr i} {
		set alist($i) [expr $minalist($i)*[expr 100**(rand()-0.5)]]
	}
	set a0 [expr $mina0*(100**(rand()-0.5))]
	set b0 [expr $minb0*(100**(rand()-0.5))]
	set b0 0
}

proc annealgeneratearray {} {
	global alist; global a0; global b0; global Nofp; global minalist; global mina0; global minb0; global minxi; global tpoints
	for {set i 0} {$i <= $Nofp} {incr i} {
		set alist($i) [expr $minalist($i)*((1e3/acos(-1)*sqrt($minxi/$tpoints))**(2*rand()-1))]
	}
	set a0 [expr $mina0*(1+(1e3/acos(-1)*sqrt($minxi/$tpoints))**(2*rand()-1))*(-1)**(int(2*rand()))]
	set b0 [expr $minb0*(1+(1e3/acos(-1)*sqrt($minxi/$tpoints))**(2*rand()-1))*(-1)**(int(2*rand()))]
	set b0 0
}

proc tryplot {} {
	global a0; global mina0; global alist; global b0; global minb0; global minxi
	global tlist; global minalist; global datasteps; global datalist; global exponents; global stopsum
	global Nofp
	generatearray
	
	comment {
	set xi 0
	set sums 0
	
	for {set i 0} {$i < [array size datalist]} {incr i} {
		set x $datasteps($i)
		set y [expr $a0+$datasteps($i)*$b0]
		
		comment {
		for {set j 0} {$j <= $Nofp} {incr j} {
			#set y [expr $y + $alist($j)*exp(-$x/$tlist($j))]
			#set y [expr $y + $alist($j)*[lindex [lindex $exponents $j] $i]]
			set y [expr $y + $alist($j)*$exponents($i,$j)]
		}
		}
		
		for {set j 0} {$j <= $Nofp} {incr j} {
			#set y [expr $y + $alist($j)*exp(-$x/$tlist($j))]
			#set y [expr $y + $alist($j)*[lindex [lindex $exponents $j] $i]]
			if {$i < $stopsum($j)} {set y [expr $y + $alist($j)*$exponents($i,$j)]}
		}
				
		dot $x $y
		set xi [expr $xi + ($y-$datalist($i))**2]
	}
	
	comment {
	for {set j 0} {$j <= $Nofp} {incr j} {
		dot [expr $tlist($j)-2] $alist($j)
	}
	dot 0 $a0
	}
	}
	
	set xi [xicalc]
	
	puts $xi
	if {$xi < $minxi} {
		set minxi $xi
		set mina0 $a0
		set minb0 $b0
		array set minalist [array get alist]
	}
	plotmin
}

proc generation {Nofg} {
	global minxi; global mina0; global minb0; global minalist; global Nofp; global tlist
	set timestamp [clock milliseconds]
	
	for {set i 1} {$i <= $Nofg} {incr i} {
		firsttryplotwographs
		if {[expr ($i*100%$Nofg)] == 0} {
			.p1 configure -value [expr ($i*100/$Nofg)]
			update
		}
	}
	for {set i 0} {$i <= $Nofp} {incr i} {
		puts "$i $tlist($i) $minalist($i)"
	}
	puts $mina0
	puts $minb0
	puts $minxi
	plotmin
	puts [expr [clock milliseconds] - $timestamp]
}

proc precgeneration {Nofg} {
	global minxi; global mina0; global minb0; global minalist; global Nofp; global tlist
	set timestamp [clock milliseconds]
	
	for {set i 1} {$i <= $Nofg} {incr i} {
		secondtryplotwographs
		if {[expr ($i*100%$Nofg)] == 0} {
			.p1 configure -value [expr ($i*100/$Nofg)]
			update
		}
	}
	for {set i 0} {$i <= $Nofp} {incr i} {
		puts "$i $tlist($i) $minalist($i)"
	}
	puts $mina0
	puts $minb0
	puts $minxi
	puts [expr [clock milliseconds] - $timestamp]
}

proc firsttryplotwographs {} {
	global a0; global mina0; global b0; global minb0; global minxi
	global alist; global minalist; global datalist; global datasteps; global exponents; global stopsum
	global Nofp; global flag_newminxi
	
	generatearray
	
	comment {
	set xi 0
	for {set i 0} {$i < [array size datalist]} {incr i} {
		set y [expr $a0+$b0*$datasteps($i)]
		for {set j 0} {$j <= $Nofp} {incr j} {
			#set y [expr $y + $alist($j)*exp(-$x/$tlist($j))]
			#set y [expr $y + $alist($j)*[lindex [lindex $exponents $j] $i]]
			if {$i < $stopsum($j)} {set y [expr $y + $alist($j)*$exponents($i,$j)]}
		}
		
		set xi [expr $xi + ($y-$datalist($i))**2]
	}
	}
	
	set xi [xicalc]
	
	if {$xi < $minxi} {
		set minxi $xi
		set mina0 $a0
		set minb0 $b0
		set flag_newminxi 1
		array set minalist [array get alist]
		plotmin
		update
	}
}

proc secondtryplotwographs {} {
	global a0; global mina0; global b0; global minb0; global minxi
	global alist; global minalist; global datalist; global datasteps; global exponents; global stopsum
	global Nofp
	#global tlist; global datasteps
	precgeneratearray
	set xi [xicalc]

	comment {
	set xi 0

	for {set i 0} {$i < [array size datalist]} {incr i} {
		set y [expr $a0+$b0*$datasteps($i)]
		for {set j 0} {$j <= $Nofp} {incr j} {
			#set y [expr $y + $alist($j)*exp(-$x/$tlist($j))]
			#set y [expr $y + $alist($j)*[lindex [lindex $exponents $j] $i]]
			if {$i < $stopsum($j)} {set y [expr $y + $alist($j)*$exponents($i,$j)]}
		}
		
		set xi [expr $xi + ($y-$datalist($i))**2]
	}
	}
	
	if {$xi < $minxi} {
		set minxi $xi
		set mina0 $a0
		set minb0 $b0
		plotmin
		array set minalist [array get alist]
	}
}

proc thirdtryplotwographs {} {
	global a0; global mina0; global b0; global minb0; global minxi
	global alist; global minalist; global datalist; global datasteps; global exponents; global stopsum
	global Nofp; global flag_newminxi
	annealgeneratearray
	set xi [xicalc]
	
	if {$xi < $minxi} {
		set minxi $xi
		set mina0 $a0
		set minb0 $b0
		set flag_newminxi 1
		plotmin
		array set minalist [array get alist]
	}
}

proc plotmin {} {
	global mina0; global minb0; global minalist; global tlist; global Nofp; global datasteps; global exponents
	global a1; global a2; global t1; global t2
	renewplot
	for {set i 0} {$i < [array size datasteps]} {incr i} {
		set x $datasteps($i)
		set y [expr $mina0 + $x*$minb0]
		for {set j 0} {$j <= $Nofp} {incr j} {
			set y [expr $y + $minalist($j)*$exponents($i,$j)]
		}
		dot $x $y
	}
	for {set i 0} {$i < [array size minalist]} {incr i} {
		set x $tlist($i)
		set y $minalist($i)
		set col "0099DD"
		littlecoldot $x $y $col
	}
}

proc comment {s} {}

proc unnoise {} {
	global minalist; global datasteps; global datalist; global tlist
	global a0; global b0; global alist
	global minxi; global mina0; global minb0; global Nofp
	set a0 $mina0
	set b0 $minb0
	
	array unset decreaselist
	
	for {set i 0} {$i < [array size minalist]} {incr i} {
		set decreaselist($i) 0
		set alist($i) $minalist($i)
	}
	for {set i 1} {$i < [array size minalist]} {incr i} {
		if {([expr $minalist($i)/$minalist([expr $i-1])] < -0.5) && ([expr $minalist($i)/$minalist([expr $i-1])] > -2)} {
			set decreaselist{$i} 1
			set decreaselist{[expr $i-1]} 1
		}
	}
	for {set i 0} {$i < [array size minalist]} {incr i} {
		if {$decreaselist($i) == 1} {set alist($i) [expr $alist($i)/2]}
	}
	
	set xi [xicalc]
	
	comment {
	set xi 0
	
	for {set i 0} {$i < [array size datalist]} {incr i} {
		set x $datasteps($i)
		set y $mina0
		for {set j 0} {$j <= $Nofp} {incr j} {
			set y [expr $y + $alist($j)*exp(-$x/$tlist($j))]
		}
		set xi [expr $xi + ($y-$datalist($i))**2]
	}
	}
	
	#puts $xi
	
	if {$xi < $minxi} {
		set minxi $xi
		array set minalist [array get tempalist]
		plotmin	
	}
}

proc trytoswap {} {
	global minalist; global datasteps; global datalist; global tlist
	global a0; global b0; global alist
	global mina0; global minb0; global Nofp; global minxi
	array set alist [array get minalist]
	set a0 $mina0
	set b0 $minb0
	
	for {set k 1} {$k < [array size minalist]} {incr k} {
		set tempa $alist([expr $k-1])
		set alist([expr $k-1]) [expr $alist($k)/exp($tlist($k)/$tlist([expr $k-1]))]
		set alist($k) [expr $tempa*exp($tlist($k)/$tlist([expr $k-1]))]
		set xi [xicalc]
		
		comment {
		set xi 0
	
		for {set i 0} {$i < [array size datalist]} {incr i} {
			set x $datasteps($i)
			set y $mina0
			for {set j 0} {$j <= $Nofp} {incr j} {
				set y [expr $y + $tempalist($j)*exp(-$x/$tlist($j))]
			}
			set xi [expr $xi + ($y-$datalist($i))**2]
		}
		}
		
		if {$xi < $minxi} {
			set minxi $xi
			array set minalist [array get alist]
			#puts $xi
			plotmin
		} else {
			array set alist [array get minalist]
			#set tempa $alist([expr $k-1])
			#set alist([expr $k-1]) $alist($k)
			#set alist($k) $tempa
		}
	}
	#puts $xi
}

proc trytomove {} {
	global minalist; global datasteps; global datalist; global tlist
	global a0; global b0; global alist
	global mina0; global minb0; global Nofp; global minxi
	array set alist [array get minalist]
	set a0 $mina0
	set b0 $minb0
	
	for {set k 0} {$k < [array size tlist]} {incr k} {
		set tempa $alist($k)
		set $alist($k) [expr $tempa/10]
		set flag_hold 0
		for {set i 0} {($i < [array size tlist])&&($flag_hold == 0)} {incr i} {
			set alist($i) [expr $alist($i) + $tempa*exp($tlist($k)/$tlist($i))]
			set xi [xicalc]
			
			if {$xi < $minxi} {
				set minxi $xi
				array set minalist [array get alist]
				#puts "$i, $k, $xi"
				plotmin
				set flag_hold 1
				set flag_newminxi 1
			} else {
				set $alist($i) $minalist($i)
			}
		if {$flag_hold == 0} {set $alist($i) $tempa}
		.p2 configure -value [expr double($k)/[array size tlist]*25+75]
		update
		}
	}
	#puts $xi
}

proc xicalc {} {
	global a0; global b0; global Nofp
	global datalist; global exponents; global alist; global stopsum; global datasteps
	set xi 0

	for {set i 0} {$i < [array size datalist]} {incr i} {
		set y [expr $a0+$b0*$datasteps($i)]
		for {set j 0} {($j <= $Nofp) && ($i < $stopsum($j))} {incr j} {
			#set y [expr $y + $alist($j)*exp(-$x/$tlist($j))]
			#set y [expr $y + $alist($j)*[lindex [lindex $exponents $j] $i]]
			#if {$i < $stopsum($j)} {set y [expr $y + $alist($j)*$exponents($i,$j)]}
			set y [expr $y + $alist($j)*$exponents($i,$j)]
		}
		
		set xi [expr $xi + ($y-$datalist($i))**2]
	}
	return $xi
}

proc shake {} {
	global mina0; global minb0; global a0; global b0; global minxi
	global alist; global minalist
	
	set a0 [expr $mina0*100**(rand()-1)*(-1)**int(rand()*2)]
	set b0 [expr $minb0*100**(rand()-1)*(-1)**int(rand()*2)]
	set b0 0
	array set alist [array get minalist]
	
	set xi [xicalc]
	
	#puts "$a0, $b0, $xi"
	
	if {$xi < $minxi} {
		set minxi $xi
		set mina0 $a0
		set minb0 $b0
		plotmin
	}
}

proc unnoising {} {
	unnoise
	.p2 configure -value 25
	update
	trytoswap
	.p2 configure -value 50
	update
	shake
	.p2 configure -value 75
	update
	trytomove
	.p2 configure -value 100
}

proc annealgeneration {Nofg} {
	global minxi; global mina0; global minb0; global minalist; global Nofp; global tlist; global tpoints; global flag_newminxi
	set timestamp [clock milliseconds]
	set thirdtoall 0
	
	for {set i 1} {$i <= $Nofg} {incr i} {
		if {[expr 0.1*rand()-sqrt($minxi/$tpoints)] < 0} {
			firsttryplotwographs
		} else {
			thirdtryplotwographs
			incr thirdtoall
		}
				
		if {[expr ($i*100%$Nofg)] == 0} {
			.p1 configure -value [expr ($i*100/$Nofg)]
			update
		}
		
		#if {([expr $i%100] == 0) && ([expr rand() - (20.0/acos(-1)*sqrt($minxi/$tpoints))] > 0) && ($flag_newminxi == 1)} {
		#	set flag_newminxi 0
		#	unnoising
		#}
	}
	
	for {set i 0} {$i <= $Nofp} {incr i} {
		puts "$i $tlist($i) $minalist($i)"
	}
	puts $mina0
	puts $minb0
	puts $minxi
	plotmin
	puts "[expr [clock milliseconds] - $timestamp], [expr double($thirdtoall)/$Nofg], [expr (1/acos(-1)*sqrt($minxi/$tpoints))]"
}

proc trytodelete {} {
	global Nofp; global a0; global b0; global mina0; global minb0; global minxi
	global alist; global minalist
	for {set i 0} {$i <= $Nofp} {incr i} {
		array set alist [array get minalist]
		set alist($i) 0
		set a0 $mina0
		set b0 $minb0
		set xi [xicalc]
	
		puts "$i, $xi"
		
		if {$xi < $minxi} {
			set minxi $xi
			set mina0 $a0
			set minb0 $b0
		plotmin
		}
	}
}

generatedata
