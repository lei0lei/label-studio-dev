Set objShell = CreateObject("WScript.Shell")
objShell.Run "powershell -STA -File "".\deploy.ps1""", 0
