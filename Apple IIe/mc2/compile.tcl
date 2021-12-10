# Load the ::quartus::flow Tcl package
load_package flow

# Open the FPGA revision named "my_fpga"
#project_open my_design -revision my_fpga
project_open mc2_apple2fpga -revision mc2_apple2fpga

# Compile the FPGA "my_fpga" revision
execute_flow -compile 

# To perform a full compilation followed by a simulation
#execute_flow -compile_and_simulate 	

# To determine if compilation was successful or not
# and print out a personalized message.
if {[catch {execute_flow -compile} result]} {
	puts "\nResult: $result\n"
	puts "ERROR: Compilation failed. See report files.\n"
} else {
	puts "\nINFO: Compilation was successful.\n"
}

# Create a HardCopy companion revision named "my_hcii"
#execute_hc -create_companion my_hcii

# Set "my_hcii" as the current revision before compiling it
#set_current_revision my_hcii

# Compile the HardCopy "my_hcii" revision
#execute_flow -compile

# Compare the two HardCopy companion revisions
#execute_hc -compare

# Generate HardCopy Design Readiness Check report
#execute_hc -hc_ready

# Generate a HardCopy Handoff Report
#execute_hc -handoff_report

# Archive the HardCopy Handoff Files into
# the file named "my_hcii_handoff.qar"
#execute_hc -archive my_hcii_handoff.qar

# Close the project
project_close