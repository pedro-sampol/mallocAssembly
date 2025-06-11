#include <stdio.h>
#include "meuAlocador.h"

int main (long int argc, char** argv) {
  void *a,*b,*c,*d,*e;

  iniciaAlocador(); 
  imprimeMapa();
  // 0) estado inicial

  a=(void *) alocaMem(6);
  imprimeMapa();
  b=(void *) alocaMem(9);
  imprimeMapa();
  c=(void *) alocaMem(8);
  imprimeMapa();
  d=(void *) alocaMem(7);
  imprimeMapa();
  // 1) Espero ver quatro segmentos ocupados

  liberaMem(b);
  imprimeMapa(); 
  liberaMem(d);
  imprimeMapa(); 
  // 2) Espero ver quatro segmentos alternando
  //    ocupados e livres
 
  b=(void *) alocaMem(2);
  imprimeMapa();
  d=(void *) alocaMem(5);
  imprimeMapa();
  e=(void *) alocaMem(1);
  imprimeMapa();
  // 3) Deduzam
  
	
  liberaMem(c);
  imprimeMapa(); 
  liberaMem(a);
  imprimeMapa();
  liberaMem(b);
  imprimeMapa();
  liberaMem(d);
  imprimeMapa();
  liberaMem(e);
  imprimeMapa();
   // 4) volta ao estado inicial

  finalizaAlocador();
}
