---
name: developer-policy-creation
description: 'Create, revise, or review least-privilege AWS developer policies using GuDeveloperPolicyExperimental. Use when enabling developers or dev containers to access AWS resources through Janus, adding IAM permissions for local development, reviewing developer access, or replacing broad developer permissions.'
argument-hint: 'Describe the developer workflow requiring AWS access'
---

# Developer Policy Creation

Create a `GuDeveloperPolicyExperimental` granting only the AWS permissions required for a specific development workflow.

## Procedure

1. Identify the workflow:
   - Determine what the developer runs from the dev container or local environment.
   - Find every AWS API call made by application code, scripts, infrastructure code, Packer, SDKs, and supporting tools.
   - Establish the intended account, region, stage, resources, and required tags.
   - Ask rather than guessing when these are unclear.

2. Search for reusable permissions:
   - Search existing developer policies and IAM statements in the repository.
   - Search shared Guardian CDK constructs and helpers available to the project.
   - Prefer reusing an existing policy, statement, ARN helper, parameter, or condition.
   - Verify reused permissions match the workflow and do not introduce unrelated access.
   - Do not widen permissions merely to consolidate statements.

3. Build an action-to-resource map:
   - Record why each API action is required.
   - Separate read, discovery, creation, mutation, cleanup, and role-passing operations.
   - Remove actions not demonstrated by the workflow.
   - Check AWS service authorization documentation when resource or condition support is uncertain.

4. Implement the policy:
   - Use `GuDeveloperPolicyExperimental`.
   - Use a stable `grantId` matching the Janus `DeveloperPolicyGrant`.
   - Give `friendlyName` a concise description suitable for selection in Janus.
   - Keep the policy restricted to the intended development stages.
   - Derive partition, account, stack, and other deployment values from CDK tokens or existing configuration.
   - Keep statements small enough for their purpose and restrictions to be clear.

5. Apply least privilege:
   - Use exact resource ARNs or narrowly scoped ARN patterns.
   - Restrict permissions by account, region, stage, resource tags, request tags, and service-specific conditions where supported.
   - Require request-tag conditions for resource creation and resource-tag conditions for later mutation or deletion.
   - Scope `iam:PassRole` to the exact role and constrain `iam:PassedToService`.
   - Use `Resource: "*"` only for actions that do not support resource-level permissions.
   - Do not combine wildcard resources with write actions unless AWS provides no narrower mechanism.
   - Avoid broad action wildcards except justified read-only discovery actions, such as narrowly conditioned `Describe` operations.
   - Never add credentials or secrets to the repository.

6. Explain every statement:
   - Add one terse comment immediately before every policy statement.
   - Explain why the developer workflow needs the access, not merely what the AWS action does.

   Example:

   ```typescript
   // Read deployment parameters required to start the app locally.
   allow(['ssm:GetParameter'], [parameterArn]);
   ```

7. Handle policy checks:
   - Do not set `withoutPolicyChecks` by default.
   - Use it only when necessary permissions remain narrowly scoped but cannot satisfy the construct's checks.
   - Preserve an existing suppression only after verifying it is still necessary.
   - Compensate with explicit conditions, focused CDK assertions, and a clear implementation rationale.

8. Add or update tests:
   - Assert the managed policy exists only in intended stages.
   - Assert its description, path, and grant identifier.
   - Assert sensitive actions use expected resources and conditions.
   - Assert write actions do not use unrestricted resources.
   - Assert account, region, stack, and stage values are derived correctly.
   - Update snapshots only after reviewing the complete IAM diff.

9. Validate:
   - Discover and run the repository's formatter, type checker, linter, tests, and CDK synthesis commands.
   - Review the synthesized `AWS::IAM::ManagedPolicy`.
   - Review every wildcard action, wildcard resource, and policy-check suppression.
   - Confirm the resulting Janus grant permits the required workflow without unrelated access.

## Completion Criteria

- The policy uses `GuDeveloperPolicyExperimental`.
- Every action is tied to a demonstrated development requirement.
- Existing policies or statements are reused where appropriate.
- Every statement has a terse rationale comment.
- Resources and conditions enforce least privilege.
- Broad permissions have explicit technical justification.
- Policy-check suppression is exceptional and tested.
- CDK assertions cover sensitive permissions and environment boundaries.
- Formatting, linting, compilation, tests, and synthesis pass.
