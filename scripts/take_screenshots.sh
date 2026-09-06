#!/bin/bash
# ==============================================================================
# Script Otomatis Snapshot Screenshot Simulator iPhone untuk README.md
# ==============================================================================

set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT_DIR="$PROJECT_DIR/docs/screenshots"
mkdir -p "$OUTPUT_DIR"

echo "📱 Memeriksa Simulator iOS yang sedang aktif..."

BOOTED_DEVICE=$(xcrun simctl list devices | grep "(Booted)" | head -n 1 | sed -E 's/.* \(([A-F0-9-]+)\) \(Booted\)/\1/')

if [ -z "$BOOTED_DEVICE" ]; then
    echo "⚠️ Tidak ada Simulator yang aktif. Mencari iPhone 16 / iPhone 17..."
    BOOTED_DEVICE=$(xcrun simctl list devices available | grep "iPhone" | head -n 1 | sed -E 's/.* \(([A-F0-9-]+)\).*/\1/')
    if [ -z "$BOOTED_DEVICE" ]; then
        echo "❌ Tidak ditemukan Simulator iPhone yang tersedia."
        exit 1
    fi
    echo "🚀 Menyalakan Simulator ($BOOTED_DEVICE)..."
    xcrun simctl boot "$BOOTED_DEVICE"
    open -a Simulator
    sleep 5
fi

DEVICE_NAME=$(xcrun simctl list devices | grep "$BOOTED_DEVICE" | awk -F '(' '{print $1}' | xargs)
echo "✅ Menggunakan Simulator iPhone: $DEVICE_NAME ($BOOTED_DEVICE)"

echo ""
echo "================================================================="
echo "📸 PANDUAN CEPAT PENGAMBILAN SCREENSHOT IPHONE:"
echo "1. Buka halaman yang diinginkan di Simulator iPhone."
echo "2. Ketik nomor di bawah lalu tekan Enter untuk langsung menjepret layar perangkat:"
echo "================================================================="
echo ""

capture() {
    local filename="$1"
    local desc="$2"
    local path="$OUTPUT_DIR/$filename"
    echo "📸 Mengambil screenshot iPhone untuk: $desc..."
    xcrun simctl io "$BOOTED_DEVICE" screenshot --mask black "$path" || xcrun simctl io "$BOOTED_DEVICE" screenshot "$path"
    echo "✅ Berhasil disimpan ke: docs/screenshots/$filename"
}

while true; do
    echo "Pilih halaman yang sedang tampil di simulator untuk dijepret:"
    echo "  [1] 01_tasks.png        - Layar Aktivitas & Tugas"
    echo "  [2] 02_today.png        - Layar Timeline Hari Ini"
    echo "  [3] 03_habits.png       - Layar Habit Tracker"
    echo "  [4] 04_focus.png        - Layar Timer Pomodoro / Fokus Hub"
    echo "  [5] 05_profile.png      - Layar Profil & Gamifikasi"
    echo "  [6] 06_edit_profile.png - Modal Edit Profil & Avatar"
    echo "  [7] 07_screentime.png   - Layar Screen Time"
    echo "  [8] 08_live_activity.png- Lock Screen / Dynamic Island"
    echo "  [9] 09_widget.png       - Home Screen Widget"
    echo "  [A] Jepret Screenshot Saat Ini (Auto Custom)"
    echo "  [Q] Selesai / Keluar"
    echo ""
    read -p "Masukkan pilihan [1-9 / A / Q]: " choice

    case "$choice" in
        1) capture "01_tasks.png" "Layar Aktivitas & Tugas" ;;
        2) capture "02_today.png" "Layar Timeline Hari Ini" ;;
        3) capture "03_habits.png" "Layar Habit Tracker" ;;
        4) capture "04_focus.png" "Layar Fokus Pomodoro" ;;
        5) capture "05_profile.png" "Layar Profil" ;;
        6) capture "06_edit_profile.png" "Modal Edit Profil" ;;
        7) capture "07_screentime.png" "Layar Screen Time" ;;
        8) capture "08_live_activity.png" "Live Activity" ;;
        9) capture "09_widget.png" "Widget" ;;
        [Aa])
            TIMESTAMP=$(date +%s)
            capture "screenshot_${TIMESTAMP}.png" "Custom Screen"
            ;;
        [Qq])
            echo "🎉 Selesai mengambil screenshot!"
            break
            ;;
        *)
            echo "⚠️ Pilihan tidak valid."
            ;;
    esac
    echo "-----------------------------------------------------------------"
done
