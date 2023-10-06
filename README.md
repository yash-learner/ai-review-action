# AI Review Action

## Environment Variables

The application uses the following environment variables for configuration:

1. `OPEN_AI_MODEL`: Specifies the model which OpenAI's client will use to process requests. The default is gpt-3.5-turbo.

2. `OPEN_AI_TEMPERATURE`: Adjusts the randomness of the model's output. A higher value (like 1.0) makes the output more random, while a lower value (like 0.1) makes it more deterministic. The default value is 0.1.

3. `SYSTEM_PROMPT`: Contains the default system prompt to be given to the AI. If it is not set, the system_prompt_default method will be used to create a default prompt.

4. `USER_PROMPT`: Used to customize the part of the prompt that instructs the AI about the user's role. It provides context about the task at hand.

5. `ROLE_PROMPT`: Specifies the role of the AI, such as "You are an advanced Teaching Assistant AI".

6. `INPUT_DESCRIPTION`: Used to describe the input data format. If not provided, a default input description is used.

7. `OUTPUT_DESCRIPTION`: Used to describe the desired output format for the AI's response. If not provided, a default output description is used.
8. `OPENAI_ACCESS_TOKEN`: This is the API access token obtained from OpenAI. This is a required field and doesn't have a default value.
9. `OPENAI_ORGANIZATION_ID`: This is an optional ID of your organization in OpenAI. If not provided, it defaults to an empty string.
10. `REVIEW_END_POINT`: This environment variable specifies the URL of the endpoint where the reviews are sent.
11. `REVIEW_BOT_USER_TOKEN`: This environment variable represents the token used for authorization when sending the reviews.
12. `WORKFLOW_FILE_PATH`: The path to your GitHub Actions workflow file. Default value is `.github/workflows/ci.js.yml`. Update this if you use a different path or file name for your workflow.

> Note: You need to specify USER_PROMPT and ROLE_PROMPT mandatorily unless you provide a SYSTEM_PROMPT.

## How to Set Environment Variables

In GitHub Actions, you can set environment variables for a specific step in your workflow file (.github/workflows/workflow.yml). Here's an example:

> Note: Use `|` (Literal Block Scalar) intsead of `>` (Folded Block Scalar) when writing prompts spanning multiple lines (see `USER_PROMPT` in the example below).

```yaml
name: "English Language Course L1 | Auto Grade"
on:
  push:
    branches: ["submission-*"]
env:
  OPENAI_ACCESS_TOKEN: ${{ secrets.OPENAI_ACCESS_TOKEN }}
  OPENAI_ORGANIZATION_ID: ${{ secrets.OPENAI_ORGANIZATION_ID }}
  REVIEW_BOT_USER_TOKEN: ${{ secrets.REVIEW_BOT_USER_TOKEN }}
  REVIEW_END_POINT: ${{ secrets.REVIEW_END_POINT }}

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Report status to LMS
        uses: pupilfirst/report-action@v1
        with:
          status: "in_progress"
          description: "AI Review has started reviewing the submission"
      - name: AI auto review
        id: ai-review
        uses: pupilfirst/ai-review-action@v1
        env:
          ROLE_PROMPT: "You are an advanced English Language Teaching Assistant AI. Your task involves reviewing and providing feedback on student submissions, paying meticulous attention to grammar, punctuation, and style errors."
          USER_PROMPT: |
            The conversation should include the following:
            - The specific Discord channel the conversation takes place in.
            - The initial question, marked with "Student: ", outlining the student's doubt.
            - The instructor's response, labelled with "Instructor: ", that provides a solution.
            - A follow-up question for clarification, again starting with "Student: ", to delve into what the instructor meant.

            Ensure that the student applies the lessons they learned in the current level:
            - Provide context, steps taken, and error messages for both the initial question and the follow-up.
            - Frame questions around the "why" and "how" aspects.
            - Ask for additional examples, if necessary.
            - Thank the instructor in a proper and considerate manner.

            The feedback should focus on the following areas (with the ideal condition in brackets):
            1. Providing Context & Background (The student delivers clear and detailed context, steps taken, and error messages).
            2. Clarity (The conversation is clear and easy to understand throughout).
            3. Expressing Thanks (The student thanks the instructor genuinely and appropriately).
            4. Appropriate Tone & Etiquette (The student maintains a professional and respectful tone throughout the conversation).

            Make sure to identify and highlight all grammar, punctuation, and style errors.

            The student's submission will be as follows:

            ${SUBMISSION}
      - name: Report Status to LMS.
        if: steps.ai-review.outcome == 'success'
        uses: pupilfirst/report-action@v1
        with:
          status: "success"
          description: AI has reviewed the submission successfully
```

## Things to be taken care while running the action locally

1. cp example.env .env

2. Update the values in .env file.

## Releasing a new version

1. **Delete the Local Tag**: First, delete the local `v1` tag.

   ```bash
   git tag -d v1
   ```

2. **Delete the Remote Tag**: Then, delete it on the remote repository as well.

   ```bash
   git push --delete origin v1
   ```

3. **Add the Tag to the New Commit**: Now tag the latest commit `v1`.

   ```bash
   git tag v1 <commit_sha>
   ```

4. **Push the New Tag**: Finally, push this new tag to the repository.
   ```bash
   git push origin v1
   ```
