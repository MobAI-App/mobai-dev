// Preview adapter for react-native-mmkv: an in-memory key/value store with
// the MMKV API (get/set/delete/clearAll/contains/getAllKeys, value listeners,
// the useMMKV* hooks). Empty at start. An app that reads its session from
// MMKV is seeded by writing the keys it expects in a project copy of this
// file, from the scenario's auth.currentUser() in the constructor.
import { useEffect, useState } from 'react';

type Listener = (key: string) => void;

export class MMKV {
  private data = new Map<string, string | number | boolean | ArrayBuffer>();
  private listeners = new Set<Listener>();
  constructor(_config?: unknown) {}


  private emit(key: string) {
    for (const l of this.listeners) l(key);
  }

  set(key: string, value: string | number | boolean | ArrayBuffer) {
    this.data.set(key, value);
    this.emit(key);
  }
  getString(key: string): string | undefined {
    const v = this.data.get(key);
    return typeof v === 'string' ? v : undefined;
  }
  getNumber(key: string): number | undefined {
    const v = this.data.get(key);
    return typeof v === 'number' ? v : undefined;
  }
  getBoolean(key: string): boolean | undefined {
    const v = this.data.get(key);
    return typeof v === 'boolean' ? v : undefined;
  }
  getBuffer(key: string): ArrayBuffer | undefined {
    const v = this.data.get(key);
    return v instanceof ArrayBuffer ? v : undefined;
  }
  contains(key: string): boolean {
    return this.data.has(key);
  }
  delete(key: string) {
    this.data.delete(key);
    this.emit(key);
  }
  getAllKeys(): string[] {
    return [...this.data.keys()];
  }
  clearAll() {
    const keys = this.getAllKeys();
    this.data.clear();
    for (const k of keys) this.emit(k);
  }
  recrypt() {}
  trim() {}
  get size() {
    return this.data.size;
  }
  addOnValueChangedListener(listener: Listener) {
    this.listeners.add(listener);
    return { remove: () => this.listeners.delete(listener) };
  }
}

export function createMMKV(config?: unknown) {
  return new MMKV(config);
}

const defaultInstance = new MMKV();

function useMMKVValue<T>(key: string, read: (s: MMKV) => T, instance?: MMKV): [T, (v: T | undefined) => void] {
  const store = instance ?? defaultInstance;
  const [value, setValue] = useState<T>(() => read(store));
  useEffect(() => {
    const sub = store.addOnValueChangedListener((changed) => {
      if (changed === key) setValue(read(store));
    });
    return () => sub.remove();
  }, [key, store]);
  const write = (v: T | undefined) => {
    if (v === undefined) store.delete(key);
    else store.set(key, v as never);
  };
  return [value, write];
}

export function useMMKVString(key: string, instance?: MMKV) {
  return useMMKVValue(key, (s) => s.getString(key), instance);
}
export function useMMKVNumber(key: string, instance?: MMKV) {
  return useMMKVValue(key, (s) => s.getNumber(key), instance);
}
export function useMMKVBoolean(key: string, instance?: MMKV) {
  return useMMKVValue(key, (s) => s.getBoolean(key), instance);
}
export function useMMKVObject<T>(key: string, instance?: MMKV) {
  const [raw, write] = useMMKVString(key, instance);
  const value = raw ? (JSON.parse(raw) as T) : undefined;
  return [value, (v: T | undefined) => write(v === undefined ? undefined : JSON.stringify(v))] as const;
}
export function useMMKV() {
  return defaultInstance;
}
