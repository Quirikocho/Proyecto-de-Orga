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
	Mensaje1: .asciiz "\nQue formato numerico quieres usar:\n(a=decimal empaquetado, b=Complemento a 2, c=Base 10, d=Octal, e=Hexadecimal): "
	Mensaje2:  .asciiz "Que formato quiere convertirlo:  (decimal empaquetado =a,  Complemento a 2=b, Base 10 = c, Octal = d y Hexadecimal =e): "
	Num1: .asciiz "Introduce el número: " 
	Num2: .asciiz "\nEl numero convertido es: "
	Buffer1: .space 20 #Almacena la primera opción
	Buffer2: .space 20 #Almacena la segunda opción
	BufferCon: .space 64 #para el número a convertir
.text
main:

#Muestra el mensaje1/ Pidiendo el formato de origen
    imprimir_str(Mensaje1)
    leer_str(Buffer1, 20)
  

#Muestra el mensaje 2/ Pide el formato destino
    imprimir_str(Mensaje2)
    leer_str(Buffer1, 20)
   
   #Pedir el NÚMERO a convertir
    imprimir_str(Num1)
    leer_str(BufferCon, 64)
    

#Lee el numero que vas a convertir
   
   #Muestra el resultado
    imprimir_str(Num2)
    
    # Sale del programa
    li $v0, 10
    syscall
