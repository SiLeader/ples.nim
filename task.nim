import osproc
import streams
import json

type Task* = object of RootObj
    command: string
    arguments: seq[string]
    statusOperator: string
    statusRange: seq[int]

type TaskStatusObj = object of RootObj
    code: int
    isOk: bool
    output: string
type TaskStatus* = ref TaskStatusObj


proc newTask*(command: string, arguments: seq[string], statusOperator: string = "==", statusRange: seq[int] = @[0]): Task =
    result = Task()
    result.command = command
    result.arguments = arguments
    result.statusOperator = statusOperator
    result.statusRange = statusRange


proc createTaskFromJsonObject*(jsonObject: JsonNode): Task =
    return to(jsonObject, Task)


proc isOk(self: Task, status: int): bool =
    case self.statusOperator
    of "==":
        return status == self.statusRange[0]
    of "!=":
        return status != self.statusRange[0]
    
    return false
    

proc createTaskStatus(source: Task, code: int, output: string): TaskStatus =
    result = TaskStatus()
    result.code = code
    result.isOk = source.isOk(code)
    result.output = output


proc execute*(self: Task, workingDirectory: string, stdin: string=""): TaskStatus =
    let process = startProcess(self.command, args=self.arguments, workingDir=workingDirectory, options={poStdErrToStdOut, poUsePath})
    let istream = process.inputStream()
    istream.write(stdin)
    istream.close()

    let stream = process.outputStream()
    let code = process.waitForExit()
    result = self.createTaskStatus(code, stream.readAll())
    process.close()


proc `$`*(self: TaskStatus): string =
    result = "status code: " & $(self.code) & '\n'
    result &= "success: " & $(self.isOk) & '\n'
    result &= "output:\n" & self.output


proc isSuccess*(self: TaskStatus): bool =
    return self.isOk


proc statusCode*(self: TaskStatus): int =
    return self.code


proc output*(self: TaskStatus): string =
    return self.output
