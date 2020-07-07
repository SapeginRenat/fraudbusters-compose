#!/bin/bash
set -e

clickhouse client -n <<-EOSQL
    CREATE DATABASE IF NOT EXISTS fraud;

    DROP TABLE IF EXISTS fraud.events_unique;

    create table fraud.events_unique (
      timestamp Date,
      eventTimeHour UInt64,
      eventTime UInt64,

      partyId String,
      shopId String,

      ip String,
      email String,
      bin String,
      fingerprint String,
      resultStatus String,
      amount UInt64,
      country String,
      checkedRule String,
      bankCountry String,
      currency String,
      invoiceId String,
      maskedPan String,
      bankName String,
      cardToken String,
      paymentId String,
      checkedTemplate String
    ) ENGINE = MergeTree()
    PARTITION BY toYYYYMM (timestamp)
    ORDER BY (eventTimeHour, partyId, shopId, bin, resultStatus, cardToken, email, ip, fingerprint)
    TTL timestamp + INTERVAL 3 MONTH;

    DROP TABLE IF EXISTS fraud.events_p_to_p;

    create table fraud.events_p_to_p (
      timestamp Date,
      eventTime UInt64,
      eventTimeHour UInt64,

      identityId String,
      transferId String,

      ip String,
      email String,
      bin String,
      fingerprint String,

      amount UInt64,
      currency String,

      country String,
      bankCountry String,
      maskedPan String,
      bankName String,
      cardTokenFrom String,
      cardTokenTo String,

      resultStatus String,
      checkedRule String,
      checkedTemplate String
    ) ENGINE = MergeTree()
    PARTITION BY toYYYYMM(timestamp)
    ORDER BY (eventTimeHour, identityId, cardTokenFrom, cardTokenTo, bin, fingerprint, currency);

    CREATE DATABASE IF NOT EXISTS fraud;

    DROP TABLE IF EXISTS fraud.fraud_payment;

    create table fraud.fraud_payment (

      timestamp Date,
      id String,
      eventTime String,

      partyId String,
      shopId String,

      amount UInt64,
      currency String,

      payerType String,
      paymentToolType String,
      cardToken String,
      paymentSystem String,
      maskedPan String,
      issuerCountry String,
      email String,
      ip String,
      fingerprint String,
      status String,
      rrn String,

      providerId UInt32,
      terminalId UInt32,

      tempalateId String,
      description String

    ) ENGINE = MergeTree()
    PARTITION BY toYYYYMM (timestamp)
    ORDER BY (partyId, shopId, paymentToolType, status, currency, providerId, fingerprint, cardToken, id);

    DROP TABLE IF EXISTS fraud.refund;

    create table fraud.refund
    (
        timestamp             Date,
        eventTime             UInt64,
        eventTimeHour         UInt64,

        id                    String,

        email                 String,
        ip                    String,
        fingerprint           String,

        bin                   String,
        maskedPan             String,
        cardToken             String,
        paymentSystem         String,
        paymentTool           String,

        terminal              String,
        providerId            String,
        bankCountry           String,

        partyId               String,
        shopId                String,

        amount                UInt64,
        currency              String,

        status                Enum8('pending' = 1, 'succeeded' = 2, 'failed' = 3),
        errorReason           String,
        errorCode             String,
        paymentId             String
    ) ENGINE = ReplacingMergeTree()
    PARTITION BY toYYYYMM (timestamp)
    ORDER BY (eventTimeHour, partyId, shopId, status, currency, providerId, fingerprint, cardToken, id, paymentId);

    DROP TABLE IF EXISTS fraud.payment;

    create table fraud.payment
    (
        timestamp             Date,
        eventTime             UInt64,
        eventTimeHour         UInt64,

        id                    String,

        email                 String,
        ip                    String,
        fingerprint           String,

        bin                   String,
        maskedPan             String,
        cardToken             String,
        paymentSystem         String,
        paymentTool           String,

        terminal              String,
        providerId            String,
        bankCountry           String,

        partyId               String,
        shopId                String,

        amount                UInt64,
        currency              String,

        status                Enum8('pending' = 1, 'processed' = 2, 'captured' = 3, 'cancelled' = 4, 'failed' = 5),
        errorReason           String,
        errorCode             String,
        paymentCountry        String
    ) ENGINE = ReplacingMergeTree()
    PARTITION BY toYYYYMM (timestamp)
    ORDER BY (eventTimeHour, partyId, shopId, paymentTool, status, currency, providerId, fingerprint, cardToken, id);

    DROP TABLE IF EXISTS fraud.chargeback;

    create table fraud.chargeback
    (
        timestamp             Date,
        eventTime             UInt64,
        eventTimeHour         UInt64,

        id                    String,

        email                 String,
        ip                    String,
        fingerprint           String,

        bin                   String,
        maskedPan             String,
        cardToken             String,
        paymentSystem         String,
        paymentTool           String,

        terminal              String,
        providerId            String,
        bankCountry           String,

        partyId               String,
        shopId                String,

        amount                UInt64,
        currency              String,

        status                Enum8('accepted' = 1, 'rejected' = 2, 'cancelled' = 3),

        category              Enum8('fraud' = 1, 'dispute' = 2, 'authorisation' = 3, 'processing_error' = 4),
        chargebackCode        String,
        paymentId             String
    ) ENGINE = ReplacingMergeTree()
    PARTITION BY toYYYYMM (timestamp)
    ORDER BY (eventTimeHour, partyId, shopId, category, status, currency, providerId, fingerprint, cardToken, id, paymentId);
EOSQL