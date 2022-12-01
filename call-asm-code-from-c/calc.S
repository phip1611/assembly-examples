    .globl    calc                      ## -- Begin function calc

    ## (see function definition in main.c)
    ## calc(int a <%edi>, int b <%esi>) {...}

calc:                                   ## @calc

    ## pushq    %rbp 					## no need for saving stack pointer, because we do not need local memory
    ## movq    %rsp, %rbp
                                        
    movl    %edi, %eax                  ## int a (first arg) in eax 
    
    cltd                                ## int to long
                                        ## in case (its signed and) negative we extend the first bit to keep the num negative
                                        ## https://stackoverflow.com/questions/17170388/trying-to-understand-the-assembly-instruction-cltd-on-x86

                                        ## value in %eax divided by int b (second arg) which is given in %esi
                                        ## result is stored in %eax
                                        
    idivl    %esi						## division result is in %eax
                                        ## remainder is in %edx
    
    addl    %edx, %eax                  ## add value in edx to value in eax
                                        ## resulting function is
                                        ## int c = a / b;
                                        ## int d = a % b;
                                        ## return (c + d) (via %eax)
    
    #  popq    %rbp
    retq
                                        ## -- End function
