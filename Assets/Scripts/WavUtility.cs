// WavUtility.cs
using UnityEngine;
using System.IO;

public static class WavUtility
{
    // Convert AudioClip to WAV format byte array
    public static byte[] FromAudioClip(AudioClip clip)
    {
        using (MemoryStream stream = new MemoryStream())
        {
            // WAV file header
            stream.Write(System.Text.Encoding.ASCII.GetBytes("RIFF"), 0, 4);
            stream.Write(System.BitConverter.GetBytes(36 + clip.samples * 2), 0, 4);
            stream.Write(System.Text.Encoding.ASCII.GetBytes("WAVE"), 0, 4);
            stream.Write(System.Text.Encoding.ASCII.GetBytes("fmt "), 0, 4);
            stream.Write(System.BitConverter.GetBytes(16), 0, 4);
            stream.Write(System.BitConverter.GetBytes((short)1), 0, 2);
            stream.Write(System.BitConverter.GetBytes((short)clip.channels), 0, 2);
            stream.Write(System.BitConverter.GetBytes(clip.frequency), 0, 4);
            stream.Write(System.BitConverter.GetBytes(clip.frequency * clip.channels * 2), 0, 4);
            stream.Write(System.BitConverter.GetBytes((short)(clip.channels * 2)), 0, 2);
            stream.Write(System.BitConverter.GetBytes((short)16), 0, 2);
            stream.Write(System.Text.Encoding.ASCII.GetBytes("data"), 0, 4);
            stream.Write(System.BitConverter.GetBytes(clip.samples * 2), 0, 4);

            // Write audio data
            float[] samples = new float[clip.samples * clip.channels];
            clip.GetData(samples, 0);
            for (int i = 0; i < samples.Length; i++)
            {
                short value = (short)(samples[i] * 32767);
                stream.Write(System.BitConverter.GetBytes(value), 0, 2);
            }

            return stream.ToArray();
        }
    }
}