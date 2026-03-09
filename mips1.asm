.macro imprimir_str(%label) # Macro para imprimir una cadena de caracteres
    li $v0, 4
    la $a0, %label
    syscall
.end_macro

.macro leer_str(%buffer, %size) # Macro para leer una cadena de caracteres (String)
    li $v0, 8
    la $a0, %buffer
    li $a1, %size
    syscall
.end_macro

.data
	Mensaje1: .asciiz "Que formato numerico quieres usar: (decimal empaquetado =a, Complemento a 2 = b, Base 10 =c, Octal =d y Hexadecimal =e)"
	Mensaje2:  .asciiz "Que formato quiere convertirlo:  (decimal empaquetado =a,  Complemento a 2=b, Base 10 = c, Octal = d y Hexadecimal =e)"
	Num1: .asciiz "Introduce el número: " 
	Num2: .asciiz "El numero convertido es: "
	Buffer1: .space 20 #Almacena la primera opción
	Buffer2: .space 20 #Almacena la segunda opción
	BufferCon: .space 64 #para el número a convertir
.text
main:

#Muestra el mensaje1
    imprimir_str(Mensaje1)
    leer_str(Buffer1, 20)
  #Lee el mensaje 1
    li $v0, 8
    la $a0, Buffer1
    li $a1, 64
    syscall 

#Muestra el mensaje 2

    li $v0, 4
    la $a0, Mensaje2
    syscall
  #lee el mensaje 2
    li $v0, 8
    la $a0, Buffer2
    li $a1, 64
    syscall 
    #Lee el numero que vas a convertir
    li $v0, 4
    la $a0, Num1
    syscall
  
    li $v0, 8
    syscall 
    move $t2, $v0
    
    #Lee el numero que convertiste
    li $v0, 4
    la $a0, Num2
    syscall 
    
    li $v0, 8
    syscall 
    
   
    
    # Sale del programa
    li $v0, 10
    syscall
