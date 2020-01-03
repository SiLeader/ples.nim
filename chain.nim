import task
import json
import sugar


type TaskChainObj = object of RootObj
    tasks: seq[Task]
type TaskChain* = ref TaskChainObj

type TaskChainStatusObj = object of RootObj
    phase: int
    passed: int
    status: seq[TaskStatus]
type TaskChainStatus* = ref TaskChainStatusObj


proc currentTask(chain: TaskChain, status: TaskChainStatus): Task =
    return chain.tasks[status.passed]


proc executeImpl(chain: TaskChain, status: TaskChainStatus, workingDirectory: string, stdin: string="", abortIfFail: bool = true): TaskChainStatus =
    if status.phase <= status.passed:
        return status
    let task = chain.currentTask(status)
    let onceStatus = task.execute(workingDirectory=workingDirectory, stdin=stdin)
    status.status.add(onceStatus)
    if abortIfFail and not onceStatus.isSuccess():
        return status

    status.passed += 1
    return chain.executeImpl(status, workingDirectory=workingDirectory, stdin=onceStatus.output(), abortIfFail=abortIfFail)


proc createChain*(tasks: seq[Task]): TaskChain =
    result = TaskChain()
    result.tasks = tasks


proc createChainFromJsonObject*(jsonObject: JsonNode): TaskChain =
    return createChain(lc[createTaskFromJsonObject(jo) | (jo <- jsonObject["tasks"].items), Task])


proc execute*(chain: TaskChain, workingDirectory: string="", stdin: string="", abortIfFail: bool = true): TaskChainStatus =
    let status = TaskChainStatus()
    status.phase = chain.tasks.len()
    return executeImpl(chain, status, workingDirectory=workingDirectory, stdin=stdin, abortIfFail=abortIfFail)


proc isSuccess*(status: TaskChainStatus): bool =
    return status.phase == status.passed


proc phase*(self: TaskChainStatus): int = self.phase
proc passed*(self: TaskChainStatus): int = self.passed
proc status*(self: TaskChainStatus): seq[TaskStatus] = self.status

proc `$`*(status: TaskChainStatus): string =
    result = "passed/phases: " & $(status.passed) & '/' & $(status.phase) & '\n'
    if not status.isSuccess():
        let lastStatus = status.status[status.passed]
        result &= "failed program output (status code: " & $(lastStatus.statusCode()) & "):\n"
        result &= lastStatus.output()
