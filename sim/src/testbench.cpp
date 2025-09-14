#include <stdlib.h> 
#include <iostream>
#include <cstdarg>
#include <cstdio>
#include <verilated.h>
#include "sim_utils.h"          // Contains the configuration, sim_time, and simulation helper prototypes

//----------------------------------------------------------------------------------------------------
// Main testbench
//----------------------------------------------------------------------------------------------------
int main(int argc, char** argv, char** env) {

    int trace_index = 0;
    bool is_random  = false;

    for (int i = 1; i < argc; i++) 
    {
        std::string arg = argv[i];
        if (arg == "--trace_index") 
        {
            if (i + 1 < argc) 
            {
                trace_index = std::atoi(argv[++i]);
                if (trace_index < 0) 
                {
                    std::cerr << "Error: trace_index must be a non-negative integer" << std::endl;
                    exit(EXIT_FAILURE);
                }
            } 
            else 
            {
                std::cerr << "Error: --trace_index requires a value" << std::endl;
                exit(EXIT_FAILURE);
            }
        } 
        else if (arg == "--trace_random") 
        {
            is_random = true;
        }
        else 
        {
            std::cerr << "Error: Unknown argument " << arg << std::endl;
            exit(EXIT_FAILURE);
        }
    }

    //------------------------------------------------------------------------------------------------
    // Initial Configuration
    //------------------------------------------------------------------------------------------------

    // Construct design object, and trace object
	Vsim *dut       = new Vsim;         // Design Top Module
    Vtrace *m_trace = new Vtrace;       // Trace

    // Trace configuration
    if (TRACE_SIGNALS)
    {
        Verilated::traceEverOn(true);     			                // Turn on trace switch in context
        dut->trace(m_trace, DEPTH_LEVELS);        		            // Set depth levels of the trace
        
        char waveform_file[256];
        char index[32];
        dec_2_char(trace_index, index);
        
        strcpy(waveform_file, "sim/waveform");
        #if defined(WAVEFORM_TYPE_VCD)
            strcat(waveform_file, "_");
            strcat(waveform_file, (const char*) index);
        #endif
        strcat(waveform_file, (const char*) WAVEFORM_EXTENSION);

        m_trace->open((const char*) waveform_file); 		        // Open the Waveform file to store data
    }

    //------------------------------------------------------------------------------------------------
    // Test Values
    //------------------------------------------------------------------------------------------------
 
    Verilated::randSeed(verilog_random());

    if (!is_random)
    {
        /* private_key[0] = 0x01dce7bc4bdadd91;
        private_key[1] = 0x5bfd44842512d795;
        private_key[2] = 0x6476155515f4b2f2;
        private_key[3] = 0x69f592120fb60f46;

        public_key[0] = 0x575D25B579CAD038; 
        public_key[1] = 0x0AA0CC335924119A;
        public_key[2] = 0x9C9B21B7FC74E4E7;
        public_key[3] = 0x0A4AB26A652CA791; */
    }
    else
    {
        /* private_key[0] = verilog_random();
        private_key[1] = verilog_random();
        private_key[2] = verilog_random();
        private_key[3] = verilog_random();

        public_key[0] = verilog_random(); 
        public_key[1] = verilog_random();
        public_key[2] = verilog_random();
        public_key[3] = verilog_random(); */
    }

    dut->rst_n = 0;
    verilog_delay(10, dut, m_trace);
    dut->rst_n = 1;

    // Simulate until max simulation time is reached
    while (sim_time <= 2*HALF_CYCLE*MAX_SIM_TIME) 
    {
        sim_step(dut, m_trace);
        sim_step(dut, m_trace);
    }

    //------------------------------------------------------------------------------------------------
    // End Simulation
    //------------------------------------------------------------------------------------------------

    // Remember to close the trace object to save data in the file
    if (TRACE_SIGNALS) m_trace->close();

    // Free memory
    delete dut;
    delete m_trace;
    exit(EXIT_SUCCESS);
}
