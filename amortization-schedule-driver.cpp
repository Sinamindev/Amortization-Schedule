//=======1=========2=========3=========4=========5=========6=========7=========8=========9=========0=========1=========2=========3=========4=========5=========6=========7**
//Author information
//  Author name: Sina Amini
//  Author email: sinamindev@gmail.com
//Project information
//  Project title: Amortization Schedule
//  Purpose: This program calls an assembly program which computes and returns the total interest from the 4th loan to this program
//  Status: Performs correctly on Linux 64-bit platforms with AVX
//  Project files: Project files: amortization-schedule-driver.cpp, amortization-schedule.asm, payment_calculator.cpp
//Module information
//  This module's call name: LOAN.out  This module is invoked by the user
//  Language: C++
//  Date last modified: 2014-Sep-27
//  Purpose: This module is the top level driver: it will call amortization_schedule
//  File name: amortization-schedule-driver.cpp
//  Status: In production.  No known errors.
//  Future enhancements: None planned
//Translator information
//  Gnu compiler: g++ -c -m64 -Wall -l amortization-schedule-driver.lis -o amortization-schedule-driver.o amortization-schedule-driver.cpp
//  Gnu linker:   g++ -m64 -o runme.out amortization-schedule-driver.o payment_calculator.o amortization-schedule.o 
//References and credits
//  Seyfarth
//  Professor Holliday public domain programs 
//  This module is standard C++
//Format information
//  Page width: 172 columns
//  Begin comments: 61
//  Optimal print specification: Landscape, 7 points or smaller, monospace, 8½x11 paper
//
//===== Begin code area ===================================================================================================================================================

#include <stdio.h>
#include <stdint.h>
#include <ctime>
#include <cstring>

extern "C" double amortization_schedule();

int main(){

  double return_code = -99.99;

  return_code = amortization_schedule();
  printf("%s%1.18lf%s\n","The driver received this number: ",return_code, ".  The driver will now return 0 to the operating system.  Have a nice day.");

  return 0;

}//End of main

//===== End of main =======================================================================================================================================================
