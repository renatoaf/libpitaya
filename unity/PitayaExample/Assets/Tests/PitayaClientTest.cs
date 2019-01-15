﻿using System.Collections;
using System.IO;
using System.Threading;
using NUnit.Framework;
using NUnit.Framework.Internal;
using UnityEngine;
using UnityEngine.TestTools;
using Pitaya.SimpleJson;

namespace Pitaya.Tests
{
    public class PitayaClientTest
    {
        private PitayaClient _client;
        private const string ServerHost = "a1d127034f31611e8858512b1bea90da-838011280.us-east-1.elb.amazonaws.com";
        private const int ServerPort = 3251;

        private Thread _mainThread;

        private const string TestLogFile = "my-test-log-file.txt";

        [SetUp]
        public void Setup()
        {
            _mainThread = Thread.CurrentThread;
            _client = new PitayaClient();
        }

        [TearDown]
        public void TearDown()
        {
            if (_client == null) return;
            _client.Disconnect();
            _client.Dispose();
            _client = null;
        }

        [Test]
        public void ShouldCreateClient()
        {
            Assert.NotNull(_client);
            Assert.AreEqual(_client.State, PitayaClientState.Inited);
        }

        [UnityTest]
        public IEnumerator ShouldConnectCorrectly()
        {
            var called = false;
            var connectionState = PitayaNetWorkState.Disconnected;

            _client.NetWorkStateChangedEvent += networkState =>
            {
                called = true;
                connectionState = networkState;
                Assert.AreEqual(_mainThread, Thread.CurrentThread);
            };

            _client.Connect(ServerHost, ServerPort);

            while (!called)
            {
                yield return new WaitForSeconds(0.5f);
            }

            Assert.True(called);
            Assert.AreEqual(connectionState, PitayaNetWorkState.Connected);
            Assert.AreEqual(_client.State, PitayaClientState.Connected);
        }

        [UnityTest]
        public IEnumerator ShouldNotConnectToUnavailableServer()
        {
            var called = false;
            var connectionState = PitayaNetWorkState.Disconnected;

            _client.NetWorkStateChangedEvent += networkState =>
            {
                called = true;
                connectionState = networkState;
                Assert.AreEqual(_mainThread, Thread.CurrentThread);
            };

            const string wrongServer = "1";
            const int wrongPort = 1;

            _client.Connect(wrongServer, wrongPort);

            while (!called)
            {
                yield return new WaitForSeconds(0.5f);
            }

            Assert.True(called);
            Assert.AreEqual(connectionState, PitayaNetWorkState.FailToConnect);
        }

        [UnityTest]
        public IEnumerator ShouldClientBeDisconnectedIfUsesUnauthorizedServerPort()
        {
            const int unauthorizedPort = 3252;

            var called = false;

            // Start with some initial value different from DISCONNECTED
            var connectionState = PitayaNetWorkState.Error;

            _client.NetWorkStateChangedEvent += networkState =>
            {
                called = true;
                connectionState = networkState;
                Assert.AreEqual(_mainThread, Thread.CurrentThread);
            };

            _client.Connect(ServerHost, unauthorizedPort);

            while (!called)
            {
                yield return new WaitForSeconds(0.5f);
            }

            Assert.True(called);
            Assert.AreEqual(PitayaNetWorkState.FailToConnect, connectionState);
        }

        [UnityTest]
        public IEnumerator NativeLogsCanBeSendToAFile()
        {
            PitayaClient.SetLogLevel(PitayaLogLevel.Debug);
            PitayaClient.LogToFile(TestLogFile);

            var called = false;
            var connectionState = PitayaNetWorkState.Disconnected;

            _client.NetWorkStateChangedEvent += networkState =>
            {
                called = true;
                connectionState = networkState;
                Assert.AreEqual(_mainThread, Thread.CurrentThread);
            };

            _client.Connect(ServerHost, ServerPort);

            while (!called)
            {
                yield return new WaitForSeconds(0.5f);
            }

            Assert.True(called);
            Assert.AreEqual(connectionState, PitayaNetWorkState.Connected);
            Assert.AreEqual(_client.State, PitayaClientState.Connected);

            Assert.True(File.Exists(TestLogFile));

            // NOTE: this code forces the log file to be flushed to disk. This will ensure that when we read the
            // file its contents will be larger than zero.
            _client.Dispose();
            _client = null;

            Assert.Greater(File.ReadAllText(TestLogFile).Length, 0);
        }
    }
}
