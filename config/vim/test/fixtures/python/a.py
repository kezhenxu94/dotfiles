import functools
import os


@functools.cache
def helper(x: int) -> int:
    return x + 1


class Greeter:
    def __init__(
        self,
        name: str,
    ):
        self.name = name

    @property
    def greeting(self) -> str:
        if self.name:
            return "hi " + self.name
        return "hi"


value: int = "oops"
print(helper(1), Greeter("a").greeting, os.sep)
