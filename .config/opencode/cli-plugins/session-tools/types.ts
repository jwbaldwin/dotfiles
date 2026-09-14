export type ParkedSession = {
  sessionID: string;
  title: string;
  directory: string;
  note: string;
  parkedAt: number;
};

export type BackgroundTask = {
  sessionID: string;
  originSessionID: string;
  directory: string;
  task: string;
  startedAt: number;
  error?: string;
};
