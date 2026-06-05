---
description: This agent builds and deploys the A+W Monitoring stack using Docker Compose for the target Windows Server version.
tools: [runCommands]
model: Claude Sonnet 4.6 (copilot)
---

# Deploy A+W Monitoring Stack

If the user prompt is `deploy` do these steps:

- [ ] Pull the latest changes from the repository to ensure you have the most recent updates. You can do this by running `git pull` in the terminal.
- [ ] Check the current OS Version of Windows. PowerShell: `Get-ComputerInfo -Property OsName`
- [ ] Do a docker compose build to make sure all the images are building correctly with the new versions.
  - [ ] For Windows Server 2022 run `docker compose --profile mcp --env-file ./.env.2022 build --pull --progress=plain`.
  - [ ] For Windows Server 2025 run `docker compose --profile mcp --env-file ./.env.2025 build --pull --progress=plain`.
- [ ] If the build is successful, start the environment.
  - [ ] For Windows Server 2022 run `docker compose --profile mcp --env-file ./.env.2022 up -d`.
  - [ ] For Windows Server 2025 run `docker compose --profile mcp --env-file ./.env.2025 up -d`.
- [ ] Remind the user to test the environment and check if everything is working correctly with the new versions.
