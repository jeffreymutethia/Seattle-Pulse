/* eslint-disable @typescript-eslint/no-explicit-any */
"use client"

import type React from "react"
import { useCallback, useEffect, useState, useRef } from "react"
import { Button } from "@/components/ui/button"
import {  Trash, User, Settings, Lock, Eye, EyeOff,  } from "lucide-react"
import Notification from "@/components/story/notification"
import NavBar from "@/components/nav-bar"
import { Switch } from "@/components/ui/switch"
import { Input } from "@/components/ui/input"
import { Textarea } from "@/components/ui/textarea"
import { AvatarWithFallback } from "@/components/ui/avatar-with-fallback"
import HomeLocationPicker from "@/components/forms/home-location-picker"

import DeleteAccountModal from "./components/delete-modal"
import { accountService, toggleHomeLocationVisibility, updatePasswordAndEmail } from "../services/account-service"
import { useMobile } from "../hooks/use-mobile"

type NotificationType = "success" | "error"
interface NotificationData {
  title: string
  message: string
  type: NotificationType
}

type SettingsTab = "profile" | "account" | "privacy"

export default function AccountSettings() {
  const [activeTab, setActiveTab] = useState<SettingsTab>("profile")
  const [showModal, setShowModal] = useState(false)

  const [username, setUsername] = useState("")
  const [firstName, setFirstName] = useState("")
  const [lastName, setLastName] = useState("")
  const [profilePicture, setProfilePicture] = useState("/Img.png")
  const [newProfilePicture, setNewProfilePicture] = useState<File | null>(null)
  const [bio, setBio] = useState("")
  const [homeLocation, setHomeLocation] = useState("")
  const [displayHomeLocation, setDisplayHomeLocation] = useState(true)

  const [email, setEmail] = useState("")
  const [phoneNumber, setPhoneNumber] = useState("")
  const [oldPassword, setOldPassword] = useState("")
  const [newPassword, setNewPassword] = useState("")
  const [confirmPassword, setConfirmPassword] = useState("")

  const [showPassword, setShowPassword] = useState(false)
  const [showConfirmPassword, setShowConfirmPassword] = useState(false)

  const [originalUserData, setOriginalUserData] = useState<any>(null)

  const [notification, setNotification] = useState<NotificationData | null>(null)

  const fileInputRef = useRef<HTMLInputElement>(null)
  const isMobile = useMobile()

  const normalizeUser = useCallback((user: any) => {
    if (!user || typeof user !== "object") {
      return {
        location: "",
        home_location: "",
        display_home_location: true,
      }
    }

    const rawLocation =
      (typeof user.location === "string" && user.location) ||
      (typeof user.home_location === "string" && user.home_location) ||
      ""

    const normalizedLocation = typeof rawLocation === "string" ? rawLocation : ""

    return {
      ...user,
      location: normalizedLocation,
      home_location: normalizedLocation,
      display_home_location: user.display_home_location !== false,
    }
  }, [])

  const applyUserState = useCallback(
    (user: any) => {
      setOriginalUserData(user)
      setUsername(user?.username || "")
      setFirstName(user?.first_name || "")
      setLastName(user?.last_name || "")
      setEmail(user?.email || "")
      setPhoneNumber(user?.phone_number || "")
      setProfilePicture(user?.profile_picture_url || "/Img.png")
      setBio(user?.bio || "")
      setHomeLocation(user?.location || "")
      setDisplayHomeLocation(user?.display_home_location !== false)
    },
    [
      setOriginalUserData,
      setUsername,
      setFirstName,
      setLastName,
      setEmail,
      setPhoneNumber,
      setProfilePicture,
      setBio,
      setHomeLocation,
      setDisplayHomeLocation,
    ]
  )

  const persistUser = useCallback(
    (user: any) => {
      const normalizedUser = normalizeUser(user)
      if (typeof window !== "undefined") {
        sessionStorage.setItem("user", JSON.stringify(normalizedUser))
        window.dispatchEvent(new Event("user-updated"))
      }
      applyUserState(normalizedUser)
      return normalizedUser
    },
    [applyUserState, normalizeUser]
  )

  useEffect(() => {
    if (typeof window !== "undefined") {
      const storedUser = sessionStorage.getItem("user")
      if (storedUser) {
        try {
          const user = JSON.parse(storedUser)
          if (user) {
            const normalizedUser = normalizeUser(user)
            applyUserState(normalizedUser)
          }
        } catch (error) {
          console.error("Failed to parse user from sessionStorage:", error)
        }
      }
    }
  }, [applyUserState, normalizeUser])

  useEffect(() => {
    if (notification) {
      const timer = setTimeout(() => {
        setNotification(null)
      }, 3000)
      return () => clearTimeout(timer)
    }
  }, [notification])

  const handleToggleHomeLocation = async (checked: boolean) => {
    try {
      const response = await toggleHomeLocationVisibility(checked)
      if (response.success === "success") {
        const nextDisplay = response.data?.show_home_location ?? checked
        const baseUser = originalUserData || (() => {
          if (typeof window === "undefined") return null
          const storedUser = sessionStorage.getItem("user")
          if (!storedUser) return null
          try {
            return JSON.parse(storedUser)
          } catch (error) {
            console.error("Failed to parse user from sessionStorage:", error)
            return null
          }
        })()

        if (baseUser) {
          persistUser({
            ...baseUser,
            display_home_location: nextDisplay,
          })
        } else {
          setDisplayHomeLocation(nextDisplay)
        }

        setNotification({
          title: "Success",
          message: response.message || "Neighborhood visibility updated",
          type: "success",
        })
      } else {
        setNotification({
          title: "Error",
          message: response.message || "Failed to toggle neighborhood visibility",
          type: "error",
        })
      }
    } catch (error: any) {
      console.error("Error toggling neighborhood:", error)
      setNotification({
        title: "Error",
        message: error.message || "An unexpected error occurred.",
        type: "error",
      })
    }
  }

  const handleSaveChanges = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault()

    if (!originalUserData) {
      setNotification({
        title: "Error",
        message: "Original user data not loaded.",
        type: "error",
      })
      return
    }

    const userId = sessionStorage.getItem("user_id")
    if (!userId) {
      setNotification({
        title: "Error",
        message: "User ID not found in session.",
        type: "error",
      })
      return
    }

    const payload: any = {}

    if (activeTab === "profile") {
      if (firstName !== originalUserData.first_name) {
        payload.first_name = firstName
      }
      if (lastName !== originalUserData.last_name) {
        payload.last_name = lastName
      }
      if (username !== originalUserData.username) {
        payload.username = username
      }
      if (bio !== (originalUserData.bio || "")) {
        payload.bio = bio
      }
      if (homeLocation !== (originalUserData.location || "")) {
        payload.home_location = homeLocation
      }
      if (newProfilePicture) {
        payload.profile_picture = newProfilePicture
      }
    }

    if (activeTab === "privacy") {
      const originalDisplay = originalUserData.display_home_location !== false
      if (displayHomeLocation !== originalDisplay) {
        payload.display_home_location = displayHomeLocation
      }
    }

    if (activeTab === "account") {
      const storedEmail = (originalUserData.email || "").trim().toLowerCase()
      const newEmail = email.trim().toLowerCase()
      const emailChanged = storedEmail !== newEmail

      const passwordChanged = !!newPassword || !!confirmPassword

      if (newPassword && newPassword !== confirmPassword) {
        setNotification({
          title: "Error",
          message: "Passwords do not match.",
          type: "error",
        })
        return
      }

      if (emailChanged || passwordChanged) {
        const updatePayload: any = {
          user_id: Number.parseInt(userId, 10),
        }

        if (emailChanged) {
          updatePayload.email = email.trim()
        }

        if (passwordChanged) {
          if (!oldPassword) {
            setNotification({
              title: "Error",
              message: "Please enter your current (old) password.",
              type: "error",
            })
            return
          }
          updatePayload.old_password = oldPassword
          updatePayload.new_password = newPassword
          updatePayload.confirm_new_password = confirmPassword
        }

        try {
          const response = await updatePasswordAndEmail(updatePayload)
          if (response.status === "success") {
            if (emailChanged && originalUserData) {
              persistUser({
                ...originalUserData,
                email: email.trim(),
              })
            }

            setNotification({
              title: "Success",
              message: response.message || "Account updated successfully!",
              type: "success",
            })

            setOldPassword("")
            setNewPassword("")
            setConfirmPassword("")
          } else {
            setNotification({
              title: "Error",
              message: response.message || "Failed to update account.",
              type: "error",
            })
            return
          }
        } catch (error: any) {
          setNotification({
            title: "Error",
            message: error.message || "Something went wrong updating account.",
            type: "error",
          })
          return
        }
      }

      if (phoneNumber !== (originalUserData.phone_number || "")) {
        payload.phone_number = phoneNumber
      }
    }

    if (Object.keys(payload).length > 0) {
      try {
        const response = await accountService.editProfile(payload)
        if (response.status === "success") {
          const mergedUser = {
            ...originalUserData,
            ...response.user,
            location: response.user?.location ?? payload.home_location ?? originalUserData.location ?? "",
          }
          persistUser(mergedUser)

          setNotification({
            title: "Success",
            message: response.message || "Profile updated successfully!",
            type: "success",
          })
        } else {
          setNotification({
            title: "Error",
            message: response.message || "Failed to update profile",
            type: "error",
          })
        }
      } catch (error) {
        console.error("Error updating profile:", error)
        setNotification({
          title: "Error",
          message: "An unexpected error occurred.",
          type: "error",
        })
      }
    } else if (activeTab !== "account") {
      setNotification({
        title: "No Changes",
        message: "No changes were made to update.",
        type: "error",
      })
    }
  }

  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  const handleDeleteAccount = async (reason: string, comments?: string) => {
    try {
      const response = await accountService.deleteAccount({
        username,
        reason,
        comments,
      })
      if (response.status === "success") {
        setNotification({
          title: "Account Deleted",
          message: response.message || "User deleted successfully. You will be logged out.",
          type: "success",
        })
        sessionStorage.clear()
        window.location.href = "/login"
      } else {
        setNotification({
          title: "Error",
          message: response.message || "Failed to delete user.",
          type: "error",
        })
      }
    } catch (error) {
      console.error("Error deleting user:", error)
      setNotification({
        title: "Error",
        message: "An unexpected error occurred.",
        type: "error",
      })
    }
  }

  const handleProfilePicClick = () => {
    fileInputRef.current?.click()
  }

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      const file = e.target.files[0]
      setNewProfilePicture(file)
      setProfilePicture(URL.createObjectURL(file))
    }
  }

  // Mobile layout
  if (isMobile) {
    return (
      <div className="flex flex-col min-h-screen bg-white">
        {/* Header */}
        <NavBar showLocationSelector={false} showSearch={false} title="Settings"/>
        {/* <div className="flex items-center justify-between p-4 border-b">
          <div className="flex items-center">
            <Button variant="ghost" size="icon" className="mr-2">
              <ChevronLeft className="h-5 w-5" />
            </Button>
            <h1 className="text-lg font-semibold">Settings</h1>
          </div>
          <div className="flex items-center">
            <div className="relative">
              <Bell className="h-5 w-5" />
              <span className="absolute -top-1 -right-1 bg-red-500 text-white text-xs rounded-full h-4 w-4 flex items-center justify-center">
                1
              </span>
            </div>
            <Button variant="ghost" size="icon" className="ml-4">
              <Menu className="h-5 w-5" />
            </Button>
          </div>
        </div> */}

        {/* Profile Picture */}
        <div className="flex justify-center mt-6 mb-4">
          <div className="relative ">
            <div className="rounded-full border-2 p-1  border-[#E2E8F0] w-24 h-24 flex items-center justify-center">
            <AvatarWithFallback
              src={profilePicture}
              alt="Profile"
              fallbackText={`${firstName?.[0] || ""}${lastName?.[0] || ""}` || username?.[0] || "?"}
              size="xl"
              className="w-full h-full"
            />
            </div>
            <button
              onClick={handleProfilePicClick}
              className="absolute bottom-0 right-0 border-2 border-[#ABB0B9] bg-black p-2 rounded-full"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                strokeWidth={2}
                stroke="white"
                className="w-4 h-4"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  d="M16.862 3.487a2.121 2.121 0 0 1 3 3l-10.5 10.5a2 2 0 0 1-.878.518l-3.5 1a1 1 0 0 1-1.238-1.238l1-3.5a2 2 0 0 1 .518-.878l10.5-10.5Z"
                />
              </svg>
            </button>
            <input type="file" accept="image/*" ref={fileInputRef} className="hidden" onChange={handleFileChange} />
          </div>
        </div>

        {/* Tabs */}
        <div className="flex bg-gray-100 rounded-full mx-4 p-1">
          <button
            onClick={() => setActiveTab("profile")}
            className={`flex-1 py-2 px-4 rounded-full text-sm font-medium ${
              activeTab === "profile" ? "bg-black text-white" : "text-gray-700"
            }`}
          >
            General
          </button>
          <button
            onClick={() => setActiveTab("account")}
            className={`flex-1 py-2 px-4 rounded-full text-sm font-medium ${
              activeTab === "account" ? "bg-black text-white" : "text-gray-700"
            }`}
          >
            Account
          </button>
          <button
            onClick={() => setActiveTab("privacy")}
            className={`flex-1 py-2 px-4 rounded-full text-sm font-medium ${
              activeTab === "privacy" ? "bg-black text-white" : "text-gray-700"
            }`}
          >
            Privacy
          </button>
        </div>

        {notification && (
          <Notification
            title={notification.title}
            message={notification.message}
            type={notification.type}
            onClose={() => setNotification(null)}
            onHomeClick={() => {}}
          />
        )}

        {/* Content */}
        <div className="flex-1 p-4">
          {activeTab === "profile" && (
            <form onSubmit={handleSaveChanges} className="space-y-4">
              <div className="space-y-2">
                <label htmlFor="firstName" className="block text-sm font-medium">
                  First Name
                </label>
                <Input
                  id="firstName"
                  value={firstName}
                  onChange={(e) => setFirstName(e.target.value)}
                  className="!rounded-3xl  !w-full !h-11 !border-[1px] "
                  placeholder="John"
                />
              </div>

              <div className="space-y-2">
                <label htmlFor="lastName" className="block text-sm font-medium">
                  Last Name
                </label>
                <Input
                  id="lastName"
                  value={lastName}
                  onChange={(e) => setLastName(e.target.value)}
                  className="!rounded-3xl  !w-full !h-11 !border-[1px] "
                  placeholder="Doe"
                />
              </div>

              <div className="space-y-2">
                <label htmlFor="username" className="block text-sm font-medium">
                  Username
                </label>
                <Input
                  id="username"
                  value={username}
                  onChange={(e) => setUsername(e.target.value)}
                  className="!rounded-3xl  !w-full !h-11 !border-[1px] "
                  placeholder="@johndoeaccount"
                />
              </div>

              <div className="space-y-2">
                <label htmlFor="homeLocationMobile" className="block text-sm font-medium">
                 Neighborhood
                </label>
                <HomeLocationPicker
                  inputId="homeLocationMobile"
                  value={homeLocation}
                  onChange={setHomeLocation}
                  placeholder="Choose a neighborhood..."
                  className="w-full"
                />
              </div>

              <div className="space-y-2">
                <label htmlFor="bio" className="block text-sm font-medium">
                  Bio
                </label>
                <Textarea
                  id="bio"
                  rows={4}
                  value={bio}
                  onChange={(e) => setBio(e.target.value)}
                  className="!rounded-3xl  !w-full !h-11 !border-[1px] "
                  placeholder="Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor"
                />
              </div>

              <Button type="submit" className="w-full bg-black text-white hover:bg-gray-800 rounded-full">
                Save Changes
              </Button>
            </form>
          )}

          {activeTab === "account" && (
            <div className="space-y-4">
             
             

              <form onSubmit={handleSaveChanges} className="space-y-4 mt-4">
                <div className="space-y-2">
                  <label htmlFor="email" className="block text-sm font-medium">
                    Email
                  </label>
                  <Input
                    id="email"
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    className="!rounded-3xl  !w-full !h-11 !border-[1px] "
                  />
                </div>

                <div className="space-y-2">
                  <label htmlFor="phoneNumber" className="block text-sm font-medium">
                    Phone Number
                  </label>
                  <div className="flex">
                    <div className="bg-gray-100 rounded-l-full px-4 flex items-center border border-r-0 border-gray-300">
                      +000
                    </div>
                    <Input
                      id="phoneNumber"
                      type="tel"
                      value={phoneNumber}
                      onChange={(e) => setPhoneNumber(e.target.value)}
                      className="rounded-r-full flex-1 !h-11 border border-gray-300"
                      placeholder="55 555 55 555"
                    />
                  </div>
                </div>

                <div className="space-y-2">
                  <label htmlFor="oldPassword" className="block text-sm font-medium">
                    Current Password
                  </label>
                  <Input
                    id="oldPassword"
                    type="password"
                    value={oldPassword}
                    onChange={(e) => setOldPassword(e.target.value)}
                    className="!rounded-3xl  !w-full !h-11 !border-[1px] "
                  />
                </div>

                <div className="space-y-2">
                  <label htmlFor="newPassword" className="block text-sm font-medium">
                    New Password
                  </label>
                  <div className="relative">
                    <Input
                      id="newPassword"
                      type={showPassword ? "text" : "password"}
                      value={newPassword}
                      onChange={(e) => setNewPassword(e.target.value)}
                      className="!rounded-3xl  !w-full !h-11 !border-[1px] "
                    />
                    <button
                      type="button"
                      className="absolute right-3 top-1/2 transform -translate-y-1/2"
                      onClick={() => setShowPassword(!showPassword)}
                    >
                      {showPassword ? <EyeOff className="h-5 w-5" /> : <Eye className="h-5 w-5" />}
                    </button>
                  </div>
                </div>

                <div className="space-y-2">
                  <label htmlFor="confirmPassword" className="block text-sm font-medium">
                    Confirm Password
                  </label>
                  <div className="relative">
                    <Input
                      id="confirmPassword"
                      type={showConfirmPassword ? "text" : "password"}
                      value={confirmPassword}
                      onChange={(e) => setConfirmPassword(e.target.value)}
                      className="!rounded-3xl  !w-full !h-11 !border-[1px] "
                    />
                    <button
                      type="button"
                      className="absolute right-3 top-1/2 transform -translate-y-1/2"
                      onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                    >
                      {showConfirmPassword ? <EyeOff className="h-5 w-5" /> : <Eye className="h-5 w-5" />}
                    </button>
                  </div>
                </div>

                <Button type="submit" className="w-full bg-black text-white hover:bg-gray-800 rounded-full">
                  Save Changes
                </Button>
              </form>
            </div>
          )}

          {activeTab === "privacy" && (
            <div className="space-y-6">
              <div>
                <h3 className="text-lg font-semibold mb-4">Security</h3>
                <div className="flex items-center justify-between">
                  <div>
                    <p className="font-medium">Display Neighborhood</p>
                    <p className="text-sm text-gray-500">Allow others to see your neighborhood in your profile.</p>
                  </div>
                  <Switch checked={displayHomeLocation} onCheckedChange={handleToggleHomeLocation} />
                </div>
              </div>

              <div className="pt-6 border-t border-gray-200">
                <h3 className="text-lg font-semibold mb-4">Account</h3>
                <div>
                  <p className="font-medium">Delete Account</p>
                  <p className="text-sm text-gray-500 mb-4">
                    This action is irreversible and will permanently delete all your data associated with the account.
                  </p>
                  <Button
                    onClick={() => setShowModal(true)}
                    className="w-full bg-red-600 text-white hover:bg-red-700 rounded-full"
                  >
                    <Trash className="w-5 h-5 mr-2" /> Delete My Account
                  </Button>
                </div>
              </div>
            </div>
          )}
        </div>

        {showModal && <DeleteAccountModal onClose={() => setShowModal(false)} />}
      </div>
    )
  }

  // Desktop layout (unchanged)
  return (
    <div className="flex min-h-screen bg-gray-50">
      <div className="w-64 border-r border-gray-200 bg-white">
        <div className="p-6">
          <p className="text-2xl font-bold">Settings</p>
        </div>

        <div className="mt-11">
          <button
            onClick={() => setActiveTab("profile")}
            className={`flex items-center w-full px-6 py-3 text-left ${
              activeTab === "profile" ? "bg-black text-white" : "text-gray-700 hover:bg-gray-100"
            }`}
          >
            <User className="w-5 h-5 mr-3" />
            <span>Profile</span>
          </button>

          <button
            onClick={() => setActiveTab("account")}
            className={`flex items-center w-full px-6 py-3 text-left ${
              activeTab === "account" ? "bg-black text-white" : "text-gray-700 hover:bg-gray-100"
            }`}
          >
            <Settings className="w-5 h-5 mr-3" />
            <span>Account</span>
          </button>

          <button
            onClick={() => setActiveTab("privacy")}
            className={`flex items-center w-full px-6 py-3 text-left ${
              activeTab === "privacy" ? "bg-black text-white" : "text-gray-700 hover:bg-gray-100"
            }`}
          >
            <Lock className="w-5 h-5 mr-3" />
            <span>Privacy & Security</span>
          </button>
        </div>
      </div>

      <div className="flex-1">
        <div className="px-24">
          <div className="flex justify-between items-center mb-6">
            <p className="text-2xl font-bold">
              {activeTab === "profile" && "Profile"}
              {activeTab === "account" && "Account"}
              {activeTab === "privacy" && "Privacy & Security"}
            </p>
            <div className="pt-5">
              <NavBar showLocationSelector={false} title="" showSearch={false} />
            </div>
          </div>

          {notification && (
            <Notification
              title={notification.title}
              message={notification.message}
              type={notification.type}
              onClose={() => setNotification(null)}
              onHomeClick={() => {}}
            />
          )}

          <div className="relative w-20 h-20 mb-8">
          <AvatarWithFallback
              src={profilePicture}
              alt="Profile"
              fallbackText={`${firstName?.[0] || ""}${lastName?.[0] || ""}` || username?.[0] || "?"}
              size="xl"
              className="w-full h-full"
            />
            <input type="file" accept="image/*" ref={fileInputRef} className="hidden" onChange={handleFileChange} />
            <button
              onClick={handleProfilePicClick}
              className="absolute bottom-0 right-0 border-2 border-[#ABB0B9] bg-black p-2 rounded-full"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                strokeWidth={2}
                stroke="white"
                className="w-4 h-4"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  d="M16.862 3.487a2.121 2.121 0 0 1 3 3l-10.5 10.5a2 2 0 0 1-.878.518l-3.5 1a1 1 0 0 1-1.238-1.238l1-3.5a2 2 0 0 1 .518-.878l10.5-10.5Z"
                />
              </svg>
            </button>
          </div>

          <div className="bg-white rounded-3xl border border-[#E2E8F0] p-8">
            {activeTab === "profile" && (
              <form onSubmit={handleSaveChanges} className="space-y-6">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div className="space-y-2">
                    <label htmlFor="firstName" className="block text-sm font-medium">
                      First Name
                    </label>
                    <Input
                      id="firstName"
                      value={firstName}
                      onChange={(e) => setFirstName(e.target.value)}
                      className="!rounded-3xl  !w-full !h-12 !border-[1px] !border-[#ABB0B9]"
                    />
                  </div>

                  <div className="space-y-2">
                    <label htmlFor="lastName" className="block text-sm font-medium">
                      Last Name
                    </label>
                    <Input
                      id="lastName"
                      value={lastName}
                      onChange={(e) => setLastName(e.target.value)}
                      className="!rounded-3xl  !w-full !h-12 !border-[1px] !border-[#ABB0B9]"
                    />
                  </div>
                </div>

                <div className="space-y-2">
                  <label htmlFor="username" className="block text-sm font-medium">
                    Username
                  </label>
                  <Input
                    id="username"
                    value={username}
                    onChange={(e) => setUsername(e.target.value)}
                    className="!rounded-3xl  !w-full !h-12 !border-[1px] !border-[#ABB0B9]"
                  />
                </div>

                <div className="space-y-2">
                  <label htmlFor="homeLocationDesktop" className="block text-sm font-medium">
                    Neighborhood
                  </label>
                  <HomeLocationPicker
                    inputId="homeLocationDesktop"
                    value={homeLocation}
                    onChange={setHomeLocation}
                    placeholder="Choose a neighborhood..."
                    className="w-full"
                  />
                </div>

                <div className="space-y-2">
                  <label htmlFor="bio" className="block text-sm font-medium">
                    Bio
                  </label>
                  <Textarea
                    id="bio"
                    rows={4}
                    value={bio}
                    onChange={(e) => setBio(e.target.value)}
                    className="rounded-xl !border-[#ABB0B9]"
                  />
                </div>

                <Button type="submit" className="bg-black text-white hover:bg-gray-800 rounded-full">
                  Save Changes
                </Button>
              </form>
            )}

            {/* Account Tab */}
            {activeTab === "account" && (
              <form onSubmit={handleSaveChanges} className="space-y-6">
                {/* Email */}
                <div className="space-y-2">
                  <label htmlFor="email" className="block text-sm font-medium">
                    Email
                  </label>
                  <Input
                    id="email"
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    className="!rounded-3xl  !w-full !h-12 !border-[1px] !border-[#ABB0B9]"
                  />
                </div>

                {/* Phone Number */}
                <div className="space-y-2">
                  <label htmlFor="phoneNumber" className="block text-sm font-medium">
                    Phone Number
                  </label>
                  <div className="flex">
                    <div className="bg-gray-100 rounded-l-full px-4 !h-12  flex items-center border border-r-0 border-gray-300">
                      +000
                    </div>
                    <Input
                      id="phoneNumber"
                      type="tel"
                      value={phoneNumber}
                      onChange={(e) => setPhoneNumber(e.target.value)}
                      className="rounded-r-full flex-1 !h-12 !border-[#ABB0B9] "
                      placeholder="55 555 55 555"
                    />
                  </div>
                </div>

                {/* Current Password */}
                <div className="space-y-2">
                  <label htmlFor="oldPassword" className="block text-sm font-medium">
                    Current Password
                  </label>
                  <Input
                    id="oldPassword"
                    type="password"
                    value={oldPassword}
                    onChange={(e) => setOldPassword(e.target.value)}
                    className={`!rounded-3xl  !w-full !h-12 !border-[1px] ${"!border-[#ABB0B9]"}`}
                  />
                </div>

                {/* New Password */}
                <div className="space-y-2">
                  <label htmlFor="newPassword" className="block text-sm font-medium">
                    New Password
                  </label>
                  <div className="relative">
                    <Input
                      id="newPassword"
                      type={showPassword ? "text" : "password"}
                      value={newPassword}
                      onChange={(e) => setNewPassword(e.target.value)}
                      className={`!rounded-3xl  !w-full !h-12 !border-[1px] ${"!border-[#ABB0B9]"}`}
                    />
                    <button
                      type="button"
                      className="absolute right-3 top-1/2 transform -translate-y-1/2"
                      onClick={() => setShowPassword(!showPassword)}
                    >
                      {showPassword ? <EyeOff className="h-5 w-5" /> : <Eye className="h-5 w-5" />}
                    </button>
                  </div>
                </div>

                <div className="space-y-2">
                  <label htmlFor="confirmPassword" className="block text-sm font-medium">
                    Confirm Password
                  </label>
                  <div className="relative">
                    <Input
                      id="confirmPassword"
                      type={showConfirmPassword ? "text" : "password"}
                      value={confirmPassword}
                      onChange={(e) => setConfirmPassword(e.target.value)}
                      className={`!rounded-3xl  !w-full !h-12 !border-[1px] ${"!border-[#ABB0B9]"}`}
                    />
                    <button
                      type="button"
                      className="absolute right-3 top-1/2 transform -translate-y-1/2"
                      onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                    >
                      {showConfirmPassword ? <EyeOff className="h-5 w-5" /> : <Eye className="h-5 w-5" />}
                    </button>
                  </div>
                </div>

                <Button type="submit" className="bg-black text-white hover:bg-gray-800 rounded-full">
                  Save Changes
                </Button>
              </form>
            )}

            {activeTab === "privacy" && (
              <div className="space-y-8">
                <div>
                  <h3 className="text-lg font-semibold mb-4">Security</h3>
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="font-medium">Display Neighborhood</p>
                      <p className="text-sm text-gray-500">Allow others to see your Neighborhood in your profile.</p>
                    </div>
                    <Switch checked={displayHomeLocation} onCheckedChange={handleToggleHomeLocation} />
                  </div>
                </div>

                <div className="pt-6 border-t border-gray-200">
                  <h3 className="text-lg font-semibold mb-4">Account</h3>
                  <div>
                    <p className="font-medium">Delete Account</p>
                    <p className="text-sm text-gray-500 mb-4">
                      This action is irreversible and will permanently delete all your data associated with the account.
                    </p>
                    <Button
                      onClick={() => setShowModal(true)}
                      className="bg-red-600 text-white hover:bg-red-700 rounded-full"
                    >
                      <Trash className="w-5 h-5 mr-2" /> Delete My Account
                    </Button>
                  </div>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>

      {showModal && <DeleteAccountModal onClose={() => setShowModal(false)} />}
    </div>
  )
}
