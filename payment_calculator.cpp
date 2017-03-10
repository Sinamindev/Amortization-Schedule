//=======1=========2=========3=========4=========5=========6=========7=========8=========9=========0=========1=========2=========3=========4=========5=========6=========7**
//Author information
//  Author name: Sina Amini
//  Author email: sinamindev@gmail.com
//Project information
//  Project title: Amortization Schedule
//  Purpose: This program will calculate the dollars.cents of the monthly payment based on the initial principal, interest rate, and number of months. 
//  Status: Performs correctly on Linux 64-bit platforms with AVX
//  Project files: Project files: amortization-schedule-driver.cpp, amortization-schedule.asm, payment_calculator.cpp
//Module information
//  This module's call name: runme.out  This module is invoked by the user
//  Language: C++
//  Date last modified: 2014-Sep-27
//  Purpose: This module is the top level driver: it will call amortization_schedule
//  File name: payment_calculator.cpp
//  Status: In production.  No known errors.
//  Future enhancements: None planned
//Translator information
//  Gnu compiler: g++ -c -m64 -Wall -l payment_calculator.lis -o payment_calculator.o payment_calculator.cpp
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

extern "C" double payment_calc(double, double , long );

double pow(double base, int exp)
{
    double retamount = 1;
    for(int i=0; i<exp; i++)
    {
         retamount*=base;
    }
return retamount;
}

double payment_calc(double amount, double rate, long months){
  double month_rate = rate / 12.0;
  double numer = month_rate * ( pow( (1 + month_rate), months ));
  double denom = (pow( (1 + month_rate), months)) - 1;

  double monthly = amount * (numer / denom);

  return monthly;

}
//===== End of main =======================================================================================================================================================









