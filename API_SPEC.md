# API Specification

Worry Box operates entirely on the client side. There are **no external HTTP APIs** called by this application.

## Internal Storage API

The application uses an internal JavaScript API wrapper around `localStorage` to abstract data access.

### `StorageController`

#### `addWorry(text: string): WorryObject`
Creates a new worry entry and appends it to the current day's list.

#### `getLockedWorries(): WorryObject[]`
Returns all worries that are currently in the 'locked' state.

#### `setUnlockTime(time: string): void`
Sets the daily unlock time (e.g., 18:00).

#### `checkUnlockStatus(): boolean`
Compares current system time against `unlockTime` and returns true if the box should be open.

#### `updateWorryStatus(id: string, status: string): void`
Updates a specific worry's status to 'released' or 'archived'.
