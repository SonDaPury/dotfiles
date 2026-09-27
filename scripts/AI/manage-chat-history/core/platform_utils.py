import os
import sys
import shutil
import urllib.parse
import urllib.request
from datetime import datetime
from pathlib import Path
from typing import Tuple

# ANSI color codes
RESET = "\033[0m"
BOLD = "\033[1m"
DIM = "\033[2m"
CYAN = "\033[36m"
GREEN = "\033[32m"
YELLOW = "\033[33m"
RED = "\033[31m"
MAGENTA = "\033[35m"
BLUE = "\033[34m"
BG_BLUE = "\033[44m"
BG_GRAY = "\033[100m"

def uri_to_path(uri: str) -> Path:
    """Safely converts file:/// URI to native pathlib.Path across OSes."""
    if uri.startswith("file://"):
        parsed = urllib.parse.urlparse(uri)
        # Use url2pathname to convert URL path to native OS path (e.g. C:\ on Windows)
        decoded_path = urllib.request.url2pathname(parsed.path)
        # On Windows urlparse might retain a leading slash before drive letter
        if os.name == 'nt' and len(decoded_path) > 2 and decoded_path[0] == '\\' and decoded_path[2] == ':':
            decoded_path = decoded_path[1:]
        return Path(decoded_path)
    return Path(uri)

def truncate_text(text: str, max_len: int, placeholder: str = "...") -> str:
    """Truncates text cleanly to max_len, appending placeholder if trimmed."""
    if len(text) <= max_len:
        return text
    if max_len <= len(placeholder):
        return text[:max_len]
    return text[:max_len - len(placeholder)] + placeholder

def format_relative_time(dt: datetime) -> str:
    """Returns compact human-readable date/time string."""
    if dt.tzinfo is not None:
        dt = dt.astimezone().replace(tzinfo=None)
    now = datetime.now()
    if dt.date() == now.date():
        return f"Hôm nay {dt.strftime('%H:%M')}"
    elif (now.date() - dt.date()).days == 1:
        return f"Hôm qua {dt.strftime('%H:%M')}"
    elif dt.year == now.year:
        return dt.strftime("%d/%m %H:%M")
    return dt.strftime("%d/%m/%Y")

def get_terminal_size() -> Tuple[int, int]:
    """Returns (columns, lines) of terminal."""
    size = shutil.get_terminal_size(fallback=(80, 24))
    return size.columns, size.lines

def enter_alt_screen() -> None:
    """Switch to alternate screen buffer, hide cursor, and set normal cursor mode."""
    sys.stdout.write("\033[?1049h\033[?25l\033[?1l\033>")
    sys.stdout.flush()

def exit_alt_screen() -> None:
    """Switch back to main screen buffer, show cursor, and restore keypad."""
    sys.stdout.write("\033[?1049l\033[?25h\033>")
    sys.stdout.flush()

def clear_screen() -> None:
    """Clear terminal screen and place cursor at 1,1."""
    sys.stdout.write("\033[2J\033[H")
    sys.stdout.flush()

def init_terminal() -> None:
    """Initialize Windows console for ANSI if running on Windows."""
    if os.name == 'nt':
        import ctypes
        kernel32 = ctypes.windll.kernel32
        h_out = kernel32.GetStdHandle(-11)
        mode = ctypes.c_ulong()
        kernel32.GetConsoleMode(h_out, ctypes.byref(mode))
        kernel32.SetConsoleMode(h_out, mode.value | 0x0004)

def decode_escape_sequence(seq: str) -> str:
    """Decodes ANSI escape sequences into standard key names."""
    if not seq.startswith('\x1b'):
        return seq
    if len(seq) == 1:
        return 'ESC'

    prefix = seq[1]
    # Application Mode Cursor Keys (\x1bOA, \x1bOB, etc.)
    if prefix == 'O' and len(seq) >= 3:
        mapping = {'A': 'UP', 'B': 'DOWN', 'C': 'RIGHT', 'D': 'LEFT', 'H': 'HOME', 'F': 'END'}
        return mapping.get(seq[2], 'ESC')

    # Standard CSI sequences (\x1b[A, \x1b[B, \x1b[3~, etc.)
    if prefix == '[' and len(seq) >= 3:
        ch = seq[2]
        if ch in ('A', 'B', 'C', 'D', 'H', 'F'):
            return {'A': 'UP', 'B': 'DOWN', 'C': 'RIGHT', 'D': 'LEFT', 'H': 'HOME', 'F': 'END'}[ch]
        if ch in ('1', '2', '3', '4', '5', '6', '7', '8'):
            mapping = {'1': 'HOME', '3': 'DELETE', '4': 'END', '5': 'PAGE_UP', '6': 'PAGE_DOWN'}
            return mapping.get(ch, 'ESC')

    return 'ESC'

def get_key() -> str:
    """
    Reads a single keypress or escape sequence cross-platform.
    Returns: 'UP', 'DOWN', 'LEFT', 'RIGHT', 'PAGE_UP', 'PAGE_DOWN',
             'HOME', 'END', 'ENTER', 'SPACE', 'BACKSPACE', 'ESC', 'TAB',
             or single character typed.
    """
    if os.name == 'nt':
        import msvcrt
        ch = msvcrt.getch()
        if ch in (b'\x00', b'\xe0'):  # Extended keys
            ext = msvcrt.getch()
            mapping = {
                b'H': 'UP', b'P': 'DOWN', b'K': 'LEFT', b'M': 'RIGHT',
                b'I': 'PAGE_UP', b'Q': 'PAGE_DOWN', b'G': 'HOME', b'O': 'END',
                b'S': 'DELETE'
            }
            return mapping.get(ext, '')
        if ch == b'\r':
            return 'ENTER'
        if ch == b' ':
            return 'SPACE'
        if ch == b'\x08':
            return 'BACKSPACE'
        if ch == b'\x1b':
            return 'ESC'
        if ch == b'\t':
            return 'TAB'
        try:
            return ch.decode('utf-8')
        except UnicodeDecodeError:
            return ''
    else:
        import termios
        import tty
        fd = sys.stdin.fileno()
        old_settings = termios.tcgetattr(fd)
        try:
            tty.setraw(fd)
            ch1 = sys.stdin.read(1)
            if ch1 == '\x1b':
                import select
                seq = ch1
                while True:
                    r, _, _ = select.select([sys.stdin], [], [], 0.05)
                    if not r:
                        break
                    next_char = sys.stdin.read(1)
                    seq += next_char
                    if len(seq) >= 5 or next_char in ('A', 'B', 'C', 'D', 'H', 'F', '~'):
                        break
                return decode_escape_sequence(seq)
            if ch1 in ('\r', '\n'):
                return 'ENTER'
            if ch1 == ' ':
                return 'SPACE'
            if ch1 in ('\x7f', '\x08'):
                return 'BACKSPACE'
            if ch1 == '\t':
                return 'TAB'
            if ch1 == '\x03':  # Ctrl-C
                raise KeyboardInterrupt
            return ch1
        finally:
            termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)
