# Verdict Core

A minimal on-chain arbitration engine built in Clarity for decentralized dispute resolution.

## Features

- **Juror Management**: Add and remove approved jurors
- **Dispute Creation**: Open disputes with unique IDs
- **Voting**: Jurors vote for or against dispute resolution
- **Finalization**: Resolve disputes based on vote majority
- **Error Handling**: Prevents duplicate votes, resolving already-finalized disputes, and unauthorized voting

## Key Functions

- `add-juror(juror)` - Register a juror
- `remove-juror(juror)` - Unregister a juror
- `open-dispute()` - Create a new dispute
- `vote(id, support)` - Cast a vote (true/false)
- `finalize(id)` - Resolve the dispute and return outcome
- `get-dispute(id)` - View dispute details
- `is-juror(juror)` - Check if address is an active juror
