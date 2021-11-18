package com.hello.calendar.models

import com.google.gson.annotations.SerializedName


data class Calendar(
    @SerializedName("id") val id: String,
    @SerializedName("name") val name: String,
    @SerializedName("color") val color: Int,
    @SerializedName("accountName") val accountName: String,
    @SerializedName("accountType") val accountType: String
) {
    @SerializedName("isReadOnly")
    var isReadOnly: Boolean = false
    @SerializedName("isDefault")
    var isDefault: Boolean = false
}