// Preview adapter: @react-native-clipboard/clipboard on the clipboard primitive.
import { clipboard } from 'mobai-preview';

const Clipboard = {
  getString: async () => clipboard.get() ?? '',
  setString: (text: string) => clipboard.set(text),
  hasString: async () => (clipboard.get() ?? '').length > 0,
  hasURL: async () => /^https?:\/\//.test(clipboard.get() ?? ''),
  hasNumber: async () => false,
  hasWebURL: async () => false,
  getStrings: async () => [clipboard.get() ?? ''],
  setStrings: (texts: string[]) => clipboard.set(texts[0] ?? ''),
  addListener: () => ({ remove: () => {} }),
  removeAllListeners: () => {},
};
export const useClipboard = () => [clipboard.get() ?? '', (t: string) => clipboard.set(t)] as const;
export default Clipboard;
