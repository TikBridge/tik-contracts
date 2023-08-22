
task("clientRegister",
    "Deploy LightClientRegister",
    require("./clientRegister")
)
    .addParam("chain", "chain id for light client")
    .addParam("contract", "contract for light client")


task("clientGetRange",
    "Get light client verifiable range",
    require("./clientGetRange")
)
    .addOptionalParam("manager", "light client manager address", "")
    .addParam("chain", "light client chain id")


