#function that says 'hello' to whoever you input

function Say-Hello {

$name = Read-Host -Prompt "Enter your name"

write-host "Hello $name!"

}


#calling function
Say-Hello