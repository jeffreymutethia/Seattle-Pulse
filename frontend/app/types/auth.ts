import exp from "constants"

export interface RegisterRequest {
    first_name: string
    last_name: string
    username: string
    emailOrPhoneNumber: string
    password: string
    accepted_terms_and_conditions: boolean
    home_location: string

  }
  
 export interface RegisterResponse {
    data: {
      email: string
      user_id: number
      username: string
    }
    message: string
    status: string
  }
  
  export interface VerifyOTPRequest {
    user_id: string
    otp: string
  }
  
  export interface VerifyOTPResponse {
    success: boolean
    message: string
  }

  export interface LoginRequest {
    email: string
    password: string
  }
  
  
  export interface LoginResponse {
    success: boolean
    message: string
    token: string
  }
  

  export interface ResendOTPResponse {
    status: string
    message: string
  }

  export interface ResetPasswordReqRequest {
    email: string
  }

  export interface ChangePasswordReqRequest {
    token: string
    password: string
    confirm_password: string
  }

  export interface ResetPasswordResponse {
    status: string
    message: string
  }

  export interface ResetPasswordRequest {
    password: string
    confirm_password: string
  }


  