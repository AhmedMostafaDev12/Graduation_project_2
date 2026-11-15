"""The glasses' decision logic (spec D38): pure library, no camera / BLE / storage I/O.

Imported by the Pi runtime (hardware/pi) and by the research replay (ml/replay), so the paper
tests exactly what the glasses run. Keep it light: numpy + onnxruntime only.
"""
