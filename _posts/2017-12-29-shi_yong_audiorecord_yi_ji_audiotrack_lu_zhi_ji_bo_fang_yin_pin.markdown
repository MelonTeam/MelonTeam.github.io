---
layout: post
title: "使用AudioRecord以及AudioTrack录制及播放音频"
date: 2017-12-29 01:33:00 +0800
categories: android
author: slimxu
tags: Android
---

* content
{:toc}



### AudioRecord录制

    
<!--more-->
    
    public class AudioRecorder {
    
        private static final String TAG = "AudioRecorder";
        /**
         * 采样频率
         */
        private static final int RECORDER_RATE = 44100;
        /**
         * AudioFormat.CHANNEL_IN_MONO 单声道 所有设备都支持
         * AudioFormat.CHANNEL_IN_STEREO 双声道
         */
        private static final int RECORDER_CHANNELS = AudioFormat.CHANNEL_IN_MONO;
        /**
         * 音频编码格式
         * AudioFormat.ENCODING_PCM_16BIT 所有设备都支持
         */
        private static final int RECORDER_AUDIO_FORMAT = AudioFormat.ENCODING_PCM_16BIT;
    
        /**
         * 缓冲区大小，这里使用 2*1024
         */
        private static final int BUFFER_ELEMENT_2_REC = 1024;
        private static final int BYTE_PER_ELEMENT = 2;
    
        private static final String OUTPUT_PATH = Environment.getExternalStorageDirectory() + "/MediaSample/Audio";
        private String mPcmFilePath;
        private String mWavFilePath;
    
        private AudioRecord mAudioRecord;
        private int mBufferSize;
        private boolean isRecording;
    
        public void startRecording() {
            mBufferSize = AudioRecord.getMinBufferSize(RECORDER_RATE, RECORDER_CHANNELS, RECORDER_AUDIO_FORMAT);
    
            mAudioRecord = new AudioRecord(MediaRecorder.AudioSource.MIC, RECORDER_RATE,RECORDER_CHANNELS,
                    RECORDER_AUDIO_FORMAT, BUFFER_ELEMENT_2_REC * BYTE_PER_ELEMENT);
    
            File file = new File(OUTPUT_PATH);
            if(!file.exists()) {
                file.mkdirs();
            }
            mPcmFilePath = OUTPUT_PATH + "/voice_" + System.currentTimeMillis() + ".pcm";
            mWavFilePath = mPcmFilePath.replace(".pcm", ".wav");
    
            mAudioRecord.startRecording();
            isRecording = true;
            new RecordThread().start();
        }
    
        public void stopRecording() {
            if(mAudioRecord != null) {
                isRecording = false;
                mAudioRecord.stop();
                mAudioRecord.release();
                mAudioRecord = null;
            }
        }
    
        public String getWavFilePath() {
            return mWavFilePath;
        }
    
        private class RecordThread extends Thread {
            @Override
            public void run() {
                writeAudioDataToFile();
            }
        }
    
        private void writeAudioDataToFile() {
            short[] shortDatas = new short[BUFFER_ELEMENT_2_REC];
            FileOutputStream fos = null;
            try {
                fos = new FileOutputStream(new File(mPcmFilePath));
            } catch (FileNotFoundException e) {
                e.printStackTrace();
            }
    
            if(fos == null) {
                Log.e(TAG, "Path:" + mPcmFilePath + ", not found.");
                return;
            }
    
            while (isRecording) {
                mAudioRecord.read(shortDatas, 0, BUFFER_ELEMENT_2_REC);
                byte[] byteDatas = short2byte(shortDatas);
                try {
                    fos.write(byteDatas, 0, BUFFER_ELEMENT_2_REC * BYTE_PER_ELEMENT);
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
    
            try {
                fos.close();
            } catch (IOException e) {
                e.printStackTrace();
            }
    
            long sampleRate = RECORDER_RATE;    // 采样率
            int channels = RECORDER_CHANNELS == AudioFormat.CHANNEL_IN_MONO? 1 : 2;
            int bitsPerSample = 16; // 采样点大小
            MediaUtil.pcm2wav(mPcmFilePath, mWavFilePath, mBufferSize, sampleRate, channels, bitsPerSample);
        }
    
        private byte[] short2byte(short[] shortDatas) {
            int shortArrsize = shortDatas.length;
            byte[] bytes = new byte[shortArrsize * 2];
            for (int i = 0; i < shortArrsize; i++) {
                bytes[i * 2] = (byte) (shortDatas[i] & 0x00FF);
                bytes[(i * 2) + 1] = (byte) (shortDatas[i] >> 8);
                shortDatas[i] = 0;
            }
            return bytes;
        }
    
    }
    

### PCM转WAV

    
    
    public class MediaUtil {
    
        public static final String TAG = "MediaUtil";
    
        /**
         *
         * @param pcmFilePath pcm 文件路径
         * @param wavFilePath wav 文件路径
         * @param bufferSize  AudioRecorder buffersize
         * @param sampleRate 采样率
         * @param channels  声道数
         * @param bitsPerSample 采样点大小
         */
        public static void pcm2wav(String pcmFilePath, String wavFilePath, int bufferSize, long sampleRate, int channels, int bitsPerSample) {
            File pcmFile = new File(pcmFilePath);
            if(!pcmFile.exists() || pcmFile.isDirectory()) {
                return;
            }
            File wavFile = new File(wavFilePath);
            FileInputStream pcmInputStream = null;
            FileOutputStream wavOutputStream = null;
            byte[] datas = new byte[bufferSize];
            try {
                pcmInputStream = new FileInputStream(pcmFile);
                wavOutputStream = new FileOutputStream(wavFile);
    
                long audioLength = pcmInputStream.getChannel().size();
                long totalLength = audioLength + 36;    //不包括RIFF和WAV
                writeWaveFileHeader(wavOutputStream, audioLength, totalLength, sampleRate, channels, bitsPerSample);
    
                while(pcmInputStream.read(datas) != -1) {
                    wavOutputStream.write(datas);
                }
    
            } catch (FileNotFoundException e) {
                e.printStackTrace();
            } catch (IOException e) {
                e.printStackTrace();
            } finally {
                if(pcmInputStream != null) {
                    try {
                        pcmInputStream.close();
                    } catch (IOException e) {
                        e.printStackTrace();
                    }
                }
                if(wavOutputStream != null) {
                    try {
                        wavOutputStream.close();
                    } catch (IOException e) {
                        e.printStackTrace();
                    }
                }
            }
        }
    
        /**
         * 写wav文件头
         * 所有数据使用的Little-Endian存储，也就是说对其中的数据，低位字节在前，高位字节在后
         *
         * @param out wav文件的输出流
         * @param totalAudioLen pcm文件长度
         * @param totalDataLen wav文件长度
         * @param sampleRate 采样频率 一般使用44100
         * @param channels 通道
         * @param bitsPerSample 采样点大小
         * @throws IOException
         */
        private static void writeWaveFileHeader(FileOutputStream out, long totalAudioLen,
                                         long totalDataLen, long sampleRate, int channels, int bitsPerSample) throws IOException {
            // 每秒字节数
            long byteRates = sampleRate * channels * bitsPerSample / 8;
    
            byte[] header = new byte[44];
            // RIFF标志
            header[0] = 'R';
            header[1] = 'I';
            header[2] = 'F';
            header[3] = 'F';
            // 文件长度
            header[4] = (byte) (totalDataLen & 0xff);
            header[5] = (byte) ((totalDataLen >> 8) & 0xff);
            header[6] = (byte) ((totalDataLen >> 16) & 0xff);
            header[7] = (byte) ((totalDataLen >> 24) & 0xff);
            // WAVE标志
            header[8] = 'W';
            header[9] = 'A';
            header[10] = 'V';
            header[11] = 'E';
            // fmt标志
            header[12] = 'f';
            header[13] = 'm';
            header[14] = 't';
            header[15] = ' ';
            // WAV头大小，PCM方式为16
            header[16] = 16;
            header[17] = 0;
            header[18] = 0;
            header[19] = 0;
            // 编码方式，PCM方式为1
            header[20] = 1;
            header[21] = 0;
            // 通道数量 单声道为1 双声道为2
            header[22] = (byte) channels;
            header[23] = 0;
            // 采样率
            header[24] = (byte) (sampleRate & 0xff);
            header[25] = (byte) ((sampleRate >> 8) & 0xff);
            header[26] = (byte) ((sampleRate >> 16) & 0xff);
            header[27] = (byte) ((sampleRate >> 24) & 0xff);
            // 每秒字节数 = 采样频率 * 采样快大小
            header[28] = (byte) (byteRates & 0xff);
            header[29] = (byte) ((byteRates >> 8) & 0xff);
            header[30] = (byte) ((byteRates >> 16) & 0xff);
            header[31] = (byte) ((byteRates >> 24) & 0xff);
            // 采样块大小= 声道数量 * 采样点大小 / 8
            header[32] = (byte) (channels * bitsPerSample / 8); // block align
            header[33] = 0;
            // 采样点大小
            header[34] = (byte) bitsPerSample;
            header[35] = 0;
            // data标志
            header[36] = 'd';
            header[37] = 'a';
            header[38] = 't';
            header[39] = 'a';
            // 数据长度
            header[40] = (byte) (totalAudioLen & 0xff);
            header[41] = (byte) ((totalAudioLen >> 8) & 0xff);
            header[42] = (byte) ((totalAudioLen >> 16) & 0xff);
            header[43] = (byte) ((totalAudioLen >> 24) & 0xff);
            out.write(header, 0, 44);
        }
    

### AudioTrack播放

    
    
    public class AudioPlayer {
    
        public static final String TAG = "AudioPlayer";
    
        private static final int RATE = 44100;
        private static final int CHANNELS = AudioFormat.CHANNEL_OUT_MONO;
        private static final int AUDIO_FORMAT = AudioFormat.ENCODING_PCM_16BIT;
    
        private AudioTrack mTrack;
        private int mBufferSize;
        private int mPlayPerSize;   // 每一次循环的播放块大小
    
        private byte[] mVoiceDatas;
        private String mInputFilePath;
    
        private boolean mIsPlayStart;
    
        public boolean startPlay(String wavFilePath) {
            if(mIsPlayStart) {
                Log.d(TAG, "startPlay failed, AudioPlayer is already start.");
                return false;
            }
            if(!createAudioTrack(wavFilePath)) {
                return false;
            }
            mIsPlayStart = true;
            mInputFilePath = wavFilePath;
            new PlayThread().start();
            return true;
        }
    
        public void stopPlay() {
            mIsPlayStart = false;
            if(mTrack != null) {
                mTrack.stop();
            }
        }
    
        public void release() {
            stopPlay();
            mTrack.release();
            mTrack = null;
        }
    
        private boolean createAudioTrack(String wavFilePath) {
            if(mTrack != null) {
                release();
            }
            try {
                FileInputStream wavFileInputStream = new FileInputStream(new File(wavFilePath));
                MediaUtil.WavInfo wavInfo = MediaUtil.readHeader(wavFileInputStream);
                mVoiceDatas = new byte[wavInfo.dateSize];
                wavFileInputStream.read(mVoiceDatas, 0, mVoiceDatas.length);
    
                int rate = wavInfo.rate;
                int channel = wavInfo.channels == 1? AudioFormat.CHANNEL_OUT_MONO : AudioFormat.CHANNEL_OUT_STEREO;
                int format = AUDIO_FORMAT;
    
                mBufferSize = AudioTrack.getMinBufferSize(rate, channel, format);
    
                mTrack = new AudioTrack(AudioManager.STREAM_MUSIC, rate, channel, format, mBufferSize, AudioTrack.MODE_STREAM);
                mPlayPerSize = mBufferSize * 2;
    
            } catch (IOException e) {
                e.printStackTrace();
                return false;
            }
    
            return true;
        }
    
        private class PlayThread extends Thread {
            private int mOffset;
            @Override
            public void run() {
                mTrack.play();
                while (mIsPlayStart) {
                    try {
                        int size = mTrack.write(mVoiceDatas, mOffset, mPlayPerSize);
                        mOffset += mPlayPerSize;
                        if(mOffset >= mVoiceDatas.length) {
                            break;
                        }
                    }catch (Exception e) {
                        e.printStackTrace();
                    }
                }
                stopPlay();
            }
        }
    
    }
    

