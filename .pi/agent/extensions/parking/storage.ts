import {
  mkdir,
  readFile,
  readdir,
  rename,
  rm,
  writeFile,
} from "node:fs/promises";
import { homedir } from "node:os";
import path from "node:path";

export const PARKING_STATUS_EVENT = "pi-parking/status/v1";
export const PARKING_WIDGET = "pi-parking";

export interface ParkedSession {
  version: 1;
  sessionId: string;
  sessionFile: string;
  cwd: string;
  name: string;
  note?: string;
  parkedAt: string;
}

export interface ParkingStatusEvent {
  version: 1;
  sessionId: string;
  parked: boolean;
}

const parkingDirectory = path.join(homedir(), ".pi", "agent", "parked");

function parkedSessionPath(sessionId: string): string {
  const safeSessionId = sessionId.replaceAll(/[^a-zA-Z0-9_-]/g, "_");
  return path.join(parkingDirectory, `${safeSessionId}.json`);
}

function isParkedSession(value: unknown): value is ParkedSession {
  if (!value || typeof value !== "object") return false;
  return (
    "version" in value &&
    value.version === 1 &&
    "sessionId" in value &&
    typeof value.sessionId === "string" &&
    "sessionFile" in value &&
    typeof value.sessionFile === "string" &&
    "cwd" in value &&
    typeof value.cwd === "string" &&
    "name" in value &&
    typeof value.name === "string" &&
    "parkedAt" in value &&
    typeof value.parkedAt === "string" &&
    (!("note" in value) ||
      value.note === undefined ||
      typeof value.note === "string")
  );
}

function isMissingFile(error: unknown): boolean {
  return error instanceof Error && "code" in error && error.code === "ENOENT";
}

export function isParkingStatusEvent(
  value: unknown,
): value is ParkingStatusEvent {
  if (!value || typeof value !== "object") return false;
  return (
    "version" in value &&
    value.version === 1 &&
    "sessionId" in value &&
    typeof value.sessionId === "string" &&
    "parked" in value &&
    typeof value.parked === "boolean"
  );
}

export async function saveParkedSession(record: ParkedSession): Promise<void> {
  await mkdir(parkingDirectory, { recursive: true });
  const destination = parkedSessionPath(record.sessionId);
  const temporary = `${destination}.${process.pid}.${Date.now()}.tmp`;
  await writeFile(temporary, `${JSON.stringify(record, null, 2)}\n`, "utf8");
  await rename(temporary, destination);
}

export async function readParkedSession(
  sessionId: string,
): Promise<ParkedSession | undefined> {
  try {
    const value: unknown = JSON.parse(
      await readFile(parkedSessionPath(sessionId), "utf8"),
    );
    return isParkedSession(value) ? value : undefined;
  } catch (error) {
    if (isMissingFile(error)) return undefined;
    return undefined;
  }
}

export async function listParkedSessions(): Promise<ParkedSession[]> {
  let names: string[];
  try {
    names = await readdir(parkingDirectory);
  } catch (error) {
    if (isMissingFile(error)) return [];
    throw error;
  }

  const records = await Promise.all(
    names
      .filter((name) => name.endsWith(".json"))
      .map(async (name) => {
        try {
          const value: unknown = JSON.parse(
            await readFile(path.join(parkingDirectory, name), "utf8"),
          );
          return isParkedSession(value) ? value : undefined;
        } catch {
          return undefined;
        }
      }),
  );

  return records
    .filter((record): record is ParkedSession => Boolean(record))
    .sort((left, right) => right.parkedAt.localeCompare(left.parkedAt));
}

export async function removeParkedSession(sessionId: string): Promise<void> {
  await rm(parkedSessionPath(sessionId), { force: true });
}
