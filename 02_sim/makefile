# Author: Hai Cao
# Copyright 2024
# Updated for Synopsys VCS & DVE Flow
.PHONY: sim
sim:
	@echo "-> COMPILING WITH VCS"
	@vcs -full64 -sverilog -debug_access+all -fsdb -f flist -l compile.log
	@echo "-> RUNNING SIMULATION"
	@./simv -l simulate.log

.PHONY: wave
wave:
	@echo "-> OPENING WAVEFORM IN VERDI"
	@/home/albert/MyPrograms/synopsys/Verdi3_L-2016.06-1/bin/verdi -ssf dump.fsdb &
.PHONY: gui
gui:
	@echo "-> RUNNING SIMULATION IN GUI MODE"
	@vcs -full64 -sverilog -debug_access+all -f ./flist
	@./simv -gui &

.PHONY: clean
clean:
	@echo "-> CLEANING SYNOPSYS FILES"
	@rm -rf simv simv.daidir csrc ucli.key *.vpd DVEfiles *.log *.fsdb verdiLog novas.*

.PHONY: create_filelist
create_filelist:
	@rm -f flist
	@echo "# =============== Included testbench files ==============="
	@find ./../01_tb \( -name "*.sv" -o -name "*.v" -o -name "*.svh" -o -name "*.vh" \) -exec echo "Included file:" {} \;
	@echo "# =============== Included source code files ==============="
	@find ./../00_src \( -name "*.sv" -o -name "*.v" -o -name "*.svh" -o -name "*.vh" \) -exec echo "Included file:" {} \;

	@echo "-sverilog" >> flist
	@echo "-timescale=1ns/100ps" >> flist
	@echo "# TESTBENCH FILES" >> flist
	@find ./../01_tb \( -name "*.sv" -o -name "*.v" -o -name "*.svh" -o -name "*.vh" \) >> flist
	@echo "# SOURCE CODE FILES" >> flist
	@find ./../00_src \( -name "*.sv" -o -name "*.v" -o -name "*.svh" -o -name "*.vh" \)  >> flist
