package com.example.finance_management

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import android.util.Log

/**
 * SQLite Local Database Helper implementing Section 5 of Technical Specification.
 * 100% offline, zero network requests, strictly local.
 */
class TransactionDatabaseHelper(context: Context) : SQLiteOpenHelper(
    context,
    DATABASE_NAME,
    null,
    DATABASE_VERSION
) {

    companion object {
        private const val TAG = "TxDbHelper"
        private const val DATABASE_NAME = "arc_transactions.db"
        private const val DATABASE_VERSION = 2

        const val TABLE_TRANSACTIONS = "transactions"
        const val COLUMN_ID = "id"
        const val COLUMN_FINGERPRINT = "fingerprint"
        const val COLUMN_AMOUNT = "amount"
        const val COLUMN_CURRENCY = "currency"
        const val COLUMN_PACKAGE_NAME = "package_name"
        const val COLUMN_SOURCE_TYPE = "source_type"
        const val COLUMN_STATUS = "status"
        const val COLUMN_IS_VERIFIED = "is_verified"
        const val COLUMN_TARGET_IDENTIFIER = "target_identifier"
        const val COLUMN_TITLE = "title"
        const val COLUMN_RAW_TEXT = "raw_text"
        const val COLUMN_CREATED_AT = "created_at"
    }

    override fun onCreate(db: SQLiteDatabase) {
        val createTableSql = """
            CREATE TABLE IF NOT EXISTS $TABLE_TRANSACTIONS (
                $COLUMN_ID INTEGER PRIMARY KEY AUTOINCREMENT,
                $COLUMN_FINGERPRINT TEXT,
                $COLUMN_AMOUNT REAL NOT NULL,
                $COLUMN_CURRENCY TEXT NOT NULL,
                $COLUMN_PACKAGE_NAME TEXT NOT NULL,
                $COLUMN_SOURCE_TYPE TEXT NOT NULL,
                $COLUMN_STATUS TEXT NOT NULL,
                $COLUMN_IS_VERIFIED INTEGER NOT NULL DEFAULT 0,
                $COLUMN_TARGET_IDENTIFIER TEXT NOT NULL,
                $COLUMN_TITLE TEXT,
                $COLUMN_RAW_TEXT TEXT,
                $COLUMN_CREATED_AT INTEGER NOT NULL
            );
        """.trimIndent()
        db.execSQL(createTableSql)
        db.execSQL("CREATE INDEX IF NOT EXISTS idx_tx_fingerprint ON $TABLE_TRANSACTIONS ($COLUMN_FINGERPRINT);")
        db.execSQL("CREATE INDEX IF NOT EXISTS idx_tx_created_at ON $TABLE_TRANSACTIONS ($COLUMN_CREATED_AT);")
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
        db.execSQL("DROP TABLE IF EXISTS $TABLE_TRANSACTIONS")
        onCreate(db)
    }

    fun insertTransaction(
        fingerprint: String,
        amount: Double,
        currency: String,
        packageName: String,
        sourceType: String,
        status: String,
        isVerified: Boolean,
        targetIdentifier: String,
        title: String,
        rawText: String,
        createdAt: Long
    ): Long {
        val db = writableDatabase
        val values = ContentValues().apply {
            put(COLUMN_FINGERPRINT, fingerprint)
            put(COLUMN_AMOUNT, amount)
            put(COLUMN_CURRENCY, currency)
            put(COLUMN_PACKAGE_NAME, packageName)
            put(COLUMN_SOURCE_TYPE, sourceType)
            put(COLUMN_STATUS, status)
            put(COLUMN_IS_VERIFIED, if (isVerified) 1 else 0)
            put(COLUMN_TARGET_IDENTIFIER, targetIdentifier)
            put(COLUMN_TITLE, title)
            put(COLUMN_RAW_TEXT, rawText)
            put(COLUMN_CREATED_AT, createdAt)
        }
        return try {
            db.insertWithOnConflict(
                TABLE_TRANSACTIONS,
                null,
                values,
                SQLiteDatabase.CONFLICT_IGNORE
            )
        } catch (e: Exception) {
            Log.e(TAG, "Error inserting transaction: ${e.message}")
            -1L
        }
    }

    fun markVerifiedByPush(id: Long, rawPushText: String) {
        val db = writableDatabase
        val values = ContentValues().apply {
            put(COLUMN_IS_VERIFIED, 1)
            put(COLUMN_STATUS, "VERIFIED_BY_PUSH")
            if (rawPushText.isNotEmpty()) {
                put(COLUMN_RAW_TEXT, rawPushText)
            }
        }
        try {
            db.update(
                TABLE_TRANSACTIONS,
                values,
                "$COLUMN_ID = ?",
                arrayOf(id.toString())
            )
        } catch (e: Exception) {
            Log.e(TAG, "Error updating transaction to verified: ${e.message}")
        }
    }

    /**
     * Query active records within the sliding TTL window (default 15 minutes).
     */
    fun findMatchingRecentTransaction(
        amount: Double,
        currency: String,
        targetIdentifier: String,
        windowStartTime: Long
    ): StoredTransaction? {
        val db = readableDatabase
        val query = """
            SELECT * FROM $TABLE_TRANSACTIONS
            WHERE $COLUMN_CREATED_AT >= ?
            AND ABS($COLUMN_AMOUNT - ?) < 0.01
            ORDER BY $COLUMN_CREATED_AT DESC
            LIMIT 5
        """.trimIndent()

        val cursor = db.rawQuery(
            query,
            arrayOf(windowStartTime.toString(), amount.toString())
        )

        cursor.use { c ->
            while (c.moveToNext()) {
                val existingTarget = c.getString(c.getColumnIndexOrThrow(COLUMN_TARGET_IDENTIFIER))
                val isCompatible = targetIdentifier == "UNKNOWN" ||
                        existingTarget == "UNKNOWN" ||
                        existingTarget.equals(targetIdentifier, ignoreCase = true) ||
                        existingTarget.contains(targetIdentifier, ignoreCase = true) ||
                        targetIdentifier.contains(existingTarget, ignoreCase = true)

                if (isCompatible) {
                    val rawTitle = c.getString(c.getColumnIndexOrThrow(COLUMN_TITLE)) ?: ""
                    val rawBody = c.getString(c.getColumnIndexOrThrow(COLUMN_RAW_TEXT)) ?: ""
                    val isIncome = BankPatternConfig.isIncomeTransaction("$rawTitle $rawBody")

                    return StoredTransaction(
                        id = c.getLong(c.getColumnIndexOrThrow(COLUMN_ID)),
                        fingerprint = c.getString(c.getColumnIndexOrThrow(COLUMN_FINGERPRINT)),
                        amount = c.getDouble(c.getColumnIndexOrThrow(COLUMN_AMOUNT)),
                        currency = c.getString(c.getColumnIndexOrThrow(COLUMN_CURRENCY)),
                        packageName = c.getString(c.getColumnIndexOrThrow(COLUMN_PACKAGE_NAME)),
                        sourceType = c.getString(c.getColumnIndexOrThrow(COLUMN_SOURCE_TYPE)),
                        status = c.getString(c.getColumnIndexOrThrow(COLUMN_STATUS)),
                        isVerified = c.getInt(c.getColumnIndexOrThrow(COLUMN_IS_VERIFIED)) == 1,
                        targetIdentifier = existingTarget,
                        title = rawTitle,
                        rawText = rawBody,
                        createdAt = c.getLong(c.getColumnIndexOrThrow(COLUMN_CREATED_AT)),
                        isIncome = isIncome
                    )
                }
            }
        }
        return null
    }
}

data class StoredTransaction(
    val id: Long,
    val fingerprint: String,
    val amount: Double,
    val currency: String,
    val packageName: String,
    val sourceType: String,
    val status: String,
    val isVerified: Boolean,
    val targetIdentifier: String,
    val title: String,
    val rawText: String,
    val createdAt: Long,
    val isIncome: Boolean = false
)
