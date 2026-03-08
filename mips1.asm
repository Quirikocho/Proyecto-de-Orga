.data
	Mensaje1: .asciiz "Que formato numerico quieres usar: (decimal empaquetado =a, Complemento a 2 = b, Base 10 =c, Octal =d y Hexadecimal =e)"
	Mensaje2:  .asciiz "Que formato quiere convertirlo:  (decimal empaquetado =a,  Complemento a 2=b, Base 10 = c, Octal = d y Hexadecimal =e)"
	Num1: .asciiz "Introduce el número: " 
	Num2: .asciiz "El numero convertido es: "
	Buffer1: .space 20 #Almacena la primera opción
	Buffer2: .space 20 #Almacena la segunda opción

.text
main:

#Muestra el mensaje1
    li $v0, 4
    la $a0, Mensaje1 
    syscall
  #Lee el mensaje 1
    li $v0, 8
    la $a0, Buffer1
    li $a1, 20
    syscall 

#Muestra el mensaje 2

    li $v0, 4
    la $a0, Mensaje2
    syscall
  #lee el mensaje 2
    li $v0, 8
    la $a0, Buffer2
    li $a1, 20
    syscall 
    #Lee el numero que vas a convertir
    li $v0, 4
    la $a0, Num1
    syscall
  
    li $v0, 5
    syscall 
    move $t2, $v0
    
   
    
    # Sale del programa
    li $v0, 10
    syscall
