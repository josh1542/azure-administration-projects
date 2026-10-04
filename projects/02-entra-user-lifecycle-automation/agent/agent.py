import asyncio
import csv
import json
import re
from datetime import datetime
from pathlib import Path

from agent_framework import Agent, Message, tool
from agent_framework.ollama import OllamaChatClient


# Project file locations
PROJECT_DIR = Path(__file__).resolve().parent.parent
USERS_FILE = PROJECT_DIR / "data" / "sample-users.json"
AUDIT_FILE = PROJECT_DIR / "logs" / "agent-audit.csv"


def load_users():
    with USERS_FILE.open("r", encoding="utf-8") as file:
        return json.load(file)


def find_user_record(identifier: str):
    """Return a matching local user record, or None."""
    identifier = identifier.strip().lower()

    for user in load_users():
        if (
            user["displayName"].lower() == identifier
            or user["userPrincipalName"].lower() == identifier
        ):
            return user

    return None


def request_explicitly_names_user(request: str, user: dict) -> bool:
    """Require the request to explicitly contain the selected user's name or UPN."""
    request_lower = request.lower()

    return (
        user["displayName"].lower() in request_lower
        or user["userPrincipalName"].lower() in request_lower
    )


def write_audit(action, user, status, workflow):
    AUDIT_FILE.parent.mkdir(exist_ok=True)
    needs_header = not AUDIT_FILE.exists()

    with AUDIT_FILE.open("a", newline="", encoding="utf-8") as file:
        writer = csv.writer(file)

        if needs_header:
            writer.writerow(
                ["Timestamp", "Action", "User", "Status", "Workflow"]
            )

        writer.writerow(
            [
                datetime.now().astimezone().isoformat(timespec="seconds"),
                action,
                user,
                status,
                workflow,
            ]
        )


@tool
def find_user(identifier: str) -> str:
    """Find a user in the local test data."""

    user = find_user_record(identifier)

    if user is not None:
        return json.dumps(user)

    return "User not found."


# Onboarding requires administrator approval.
@tool(approval_mode="always_require")
def prepare_onboarding(
    first_name: str,
    last_name: str,
    job_title: str,
    department: str,
) -> str:
    """Prepare an onboarding request for the existing PowerShell workflow."""

    upn = f"{first_name}.{last_name}@contoso.onmicrosoft.com".lower()

    write_audit(
        "Onboarding",
        upn,
        "Approved",
        "New-User.ps1",
    )

    return (
        f"Onboarding simulated for {first_name} {last_name}. "
        "No Microsoft Entra ID changes were made."
    )


# Offboarding always requires administrator approval.
@tool(approval_mode="always_require")
def prepare_offboarding(user_principal_name: str) -> str:
    """Prepare an offboarding request for the existing PowerShell workflow."""

    write_audit(
        "Offboarding",
        user_principal_name,
        "Approved",
        "Offboard-User.ps1",
    )

    return (
        f"Offboarding simulated for {user_principal_name}. "
        "No Microsoft Entra ID changes were made."
    )


def get_approval():
    while True:
        answer = input("\nApprove this action? (y/n): ").strip().lower()

        if answer in ("y", "n"):
            return answer == "y"

        print("Please enter y or n.")


async def run_request(request, agent):
    result = await agent.run(request)

    # Normal requests return immediately. Approval requests are handled below.
    if not result.user_input_requests:
        return result.text

    approval = result.user_input_requests[0]
    call = approval.function_call

    if call is None:
        return result.text

    if call.name == "prepare_offboarding":
        action = "Offboarding"
        user = call.arguments.get("user_principal_name", "Unknown")
        workflow = "Offboard-User.ps1"

        # Deterministic validation: the selected account must exist locally.
        user_record = find_user_record(user)

        if user_record is None:
            return (
                f"User '{user}' was not found in the local test data. "
                "Offboarding cannot proceed."
            )

        # The request must explicitly identify the same user selected by the model.
        # This prevents vague requests from being turned into guessed accounts.
        if not request_explicitly_names_user(request, user_record):
            return (
                "A specific user name or user principal name is required. "
                "No action was taken."
            )

    elif call.name == "prepare_onboarding":
        action = "Onboarding"
        first_name = call.arguments.get("first_name", "").strip()
        last_name = call.arguments.get("last_name", "").strip()
        job_title = call.arguments.get("job_title", "").strip()
        department = call.arguments.get("department", "").strip()

        if not all((first_name, last_name, job_title, department)):
            return (
                "First name, last name, job title and department are required. "
                "No action was taken."
            )

        user = f"{first_name} {last_name}".strip()
        workflow = "New-User.ps1"

        # Deterministic duplicate validation before approval.
        upn = f"{first_name}.{last_name}@contoso.onmicrosoft.com".lower()

        if (
            find_user_record(user) is not None
            or find_user_record(upn) is not None
        ):
            return (
                f"User {user} already exists in the system. "
                "No onboarding can be performed."
            )

    else:
        return "Unsupported approval request. No action was taken."

    print("\n--- Approval Required ---")
    print(f"Tool: {call.name}")
    print(f"Arguments: {call.arguments}")

    if not get_approval():
        write_audit(
            action,
            user,
            "Rejected",
            workflow,
        )

        return f"{action} cancelled by administrator. No action was taken."

    # Continue the tool call after administrator approval.
    await agent.run(
        [
            request,
            Message(
                role="assistant",
                contents=[approval],
            ),
            Message(
                role="user",
                contents=[
                    approval.to_function_approval_response(True)
                ],
            ),
        ]
    )

    return (
        f"{action} simulation completed for {user}. "
        "No Microsoft Entra ID changes were made."
    )


async def main():
    print("Entra User Lifecycle Agent")
    print("--------------------------")
    print("Mode: DRY RUN\n")

    request = input("IT request: ").strip()

    if not request:
        print("No request entered.")
        return

    # Deterministic safety guard for unsupported permanent-deletion requests.
    request_lower = request.lower()

    if (
        re.search(r"\b(delete|purge|destroy)\b", request_lower)
        or "permanently remove" in request_lower
    ):
        print("\n--- Result ---")
        print(
            "Permanent user deletion is not supported. "
            "No action was taken."
        )
        return

    # The agent selects the request path; PowerShell handles the lifecycle actions.
    async with Agent(
        client=OllamaChatClient(),
        name="LifecycleAgent",
        instructions="""
Handle onboarding and offboarding requests for this dry-run lab.

Check the local user data before continuing and do not guess account details.

For onboarding, make sure the user does not already exist and use prepare_onboarding with the details provided in the request. Onboarding needs administrator approval.

For offboarding, make sure the user exists and use prepare_offboarding. Offboarding needs administrator approval.

If an offboarding request does not clearly identify a specific user by name or user principal name, do not guess an account.

Permanent account deletion is not supported. Never interpret a deletion request as offboarding.

Keep responses short. No changes are made to Microsoft Entra ID.
""",
        tools=[
            find_user,
            prepare_onboarding,
            prepare_offboarding,
        ],
    ) as agent:
        result = await run_request(request, agent)

    print("\n--- Result ---")
    print(result)


if __name__ == "__main__":
    asyncio.run(main())