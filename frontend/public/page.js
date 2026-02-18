"use client"

import { useState, useRef, useEffect } from "react"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Button } from "@/components/ui/button"
import { ScrollArea } from "@/components/ui/scroll-area"
import { AvatarGroup } from "../Components/avator-group"
import MessagePlaceholder from "../Components/palceholde"
import { Bell, Search } from "lucide-react"


const statusColors = {
  online: "bg-green-500",
  offline: "bg-gray-500",
  idle: "bg-yellow-500",
}

const contacts = [
  {
    id: 1,
    name: "GroupChat Name",
    type: "group",
    avatar: "https://s3-alpha-sig.figma.com/img/758d/15bd/95f361f830e413ec7a19ff25768bd4ad?Expires=1739750400&Key-Pair-Id=APKAQ4GOSFWCW27IBOMQ&Signature=S48c7fkeXD36Sq9nw~OpwLzSizGc6Z8t8hGyaaGv6bcBSP-oAEbjSXIT9Vei3e5C7LzPrGuFO5nJUmZ9vKDjR~gh7aS6dQZ-Xd65nfISxHgB64g5LX~Ahf-bcaVUrDIhur6IhnkeA379fB9LDzvgvMB~~G7XRoHkJgxc2jfTL5DZ70t-qReVXP8FB0wetJEVkI7ftTL4OP1kvJS9egeI1kDmbfe1wbcLa-KZan1pmjpkyaQZDibtmh6NB~hbUnBFe3AIgWchymuWFtVWl60J9igDcV0IJkaCqEjEwNqtsyY2V~uBP0oFucJGCU6S5akc4L~qky1kiXUWAkoy0AheYA__",
    lastMessage: "Hi Neal, I'm facing some challen...",
    members: [
      {
        id: 1,
        name: "Bessie Cooper",
        avatar: "https://s3-alpha-sig.figma.com/img/8cf0/6edb/3b87accefaf94003ebee0d072b3fead8?Expires=1739750400&Key-Pair-Id=APKAQ4GOSFWCW27IBOMQ&Signature=uCz-iyZHvSboRlJdxNN4pfrEcWIh~iB4t0cVUJzmFnx7Etdj9pk6IDd8IYzVMt53Wmz-itK-vvWp70fhEkf59lcFyI3nYu5H1Jo72j7RCWSakuJBSYDSGmDtQVSjjLhKsowusy2LPkzmwKXud7hFVIUqx6-DLRxWgoQtW-cbF50FvmeW3gbHTZmbGJxv9EMwiDhSUwhYz7~DVwfPzEx7dbl3C0CbejQiFnMgfxghXXgyY3RgrNQx7uRsI1XPgp7LQN4vIMGGpEqotPX~-0eoySl8U3QvouTOQlnIw~6kq5ZOlCo8ZlUdutipWl5EZtGEiCG1TviIpmTCqSCBSmJJOg__",
      },
      {
        id: 2,
        name: "Jenny Wilson",
        avatar: "https://s3-alpha-sig.figma.com/img/e55d/268f/2899668443420af0e566df1bbb8025c7?Expires=1739750400&Key-Pair-Id=APKAQ4GOSFWCW27IBOMQ&Signature=JwEsZnTQHsNqZIpwFp2ykRgObPL7aBgbHrPfzSznxepNfecmb-mwEPnUv1vEQ~C5oXdhkXLmlPadD78fTigHYSufq534Ii5AM4D9cL2qDMAbiW9Z9w3zY8iwqQv8cqm01yEvibIpsfzPAz5Hkcp9S-agCNUVLLxMH2F1G9RlTbGzILQh5VSlLWbYa5UfAWlY7hACH5PDR~R00p3qx3cx1ht5cC8SFh7md7YoqvPbhDLL6TqqsrvjxY10lkjto~wm5-ztzxiGqKyx5pvcYyHabHWXEcaYwCEzQo2ez6OdJeRfEyrePbVtyNLlRaX1p-mA6pqBveuTjArUpRC0-jA~mA__",
      },
      {
        id: 3,
        name: "Robert Fox",
        avatar: "https://s3-alpha-sig.figma.com/img/b7e9/8d83/0bf86ec06fa1b0caf62ed0bd7acd3580?Expires=1739750400&Key-Pair-Id=APKAQ4GOSFWCW27IBOMQ&Signature=t1eYt8dW8qRvAs8mEVjwdUHcps63BGgiyrvB8lkKsb0YnZ-XmZyEjW5ERni0URvey4zJJQ15EC~~pRfkK~fuuPMlFspVMKk-oEwYy4Mf7oneYgmxqT6LSajLCpk9XlNOtkzOjgdc~ZoZxIBVXMsPsz6oZBs8j7q0wEVrnS9CiSdblqkvTMRuLL-9Nb24cSabwD-I2LFlCmYzYhzFhHv9mnF7ieRchIV9~yQr-F-XsLAPuplXL1Ez8DbqFglLTPGLHVQYNjXZ2pMcOrVoDsIBF0U0PAVkX3Qdfrv8~k5qGWTDKgaWRHaiLVV6A1ugeoiAJeHDhozkRPHxDs0n7OJwkw__",
      },
      {
        id: 4,
        name: "Wade Warren",
        avatar: "https://s3-alpha-sig.figma.com/img/3675/887d/5ccd4ee9bbbacdf63b7812bed1a688ea?Expires=1739750400&Key-Pair-Id=APKAQ4GOSFWCW27IBOMQ&Signature=Cli3w-0tjjo~eeCSU2fzWPFeXzmC3IDnRynVw6eHFcrYudg-1b1eN6gNN9LtzVgo5VHukqwteiEPWH1mnr51~OI-TdDGw8r0FC~m6xXni3lhBImnsKVTRAheaSC9LDvT5RCehhAv7MREyDOhPlXMkJnBEhARBJwePrsjjQZmWgbrQfmC-~DFAEaK8x4Mg9gyXyO~v25Ylvn3~0SCf-7nh0Tmlzg3bX1yRS3blRBHrb2FvO867h4DYdCq0ZiMxgbEqnLtYdypYLPU8EBrqZf-v958zazWwdxgu6jhLTGLefGENaoP9oIj1wZAGxJGtJ3VqVv~lb~Xq7uGIhRElh4U7g__",
      },
    ],
  },
  {
    id: 2,
    name: "Bessie Cooper",
    type: "individual",
    status: "online",
    avatar: "https://s3-alpha-sig.figma.com/img/f127/01bd/073e2bc1cd36ec23f693b57248587006?Expires=1739750400&Key-Pair-Id=APKAQ4GOSFWCW27IBOMQ&Signature=ge6Ny6RpA3T7UQWEk~n25TZHYVWGyjCffXTwCjbT2k7zwyt7AyIb5XvvGncPtadi8EHtjtH3B3kVJ4yIqVtgo~~5IWL9w6bsMgxhty-Mum86PsEpwVwr~DLXqxAHtxqO0KbQiomw7HGQgsRKT-GYkrsFVbIdY0tdUMU96TLygOJsTMbk2sj16PKmwBrCh50bd1Q5NMAHBl-2EFQ3CFxlx3~CB0mmOk09jFjcPCX0BieaigIpFjjjjbb7wUQ0dvZKUiqMgIJwYhFbFQFyux8qKopb0BX~CwhfUZlKEw2WDAf7mRLZ5frDBvhLY0a04JyYy3eis-DJXpgDhk1Cx04eGA__",
    lastMessage: "Hi Neal, I'm facing some challen...",
  },
  {
    id: 3,
    name: "Jenny Wilson",
    type: "individual",
    status: "idle",
    avatar: "https://s3-alpha-sig.figma.com/img/f127/01bd/073e2bc1cd36ec23f693b57248587006?Expires=1739750400&Key-Pair-Id=APKAQ4GOSFWCW27IBOMQ&Signature=ge6Ny6RpA3T7UQWEk~n25TZHYVWGyjCffXTwCjbT2k7zwyt7AyIb5XvvGncPtadi8EHtjtH3B3kVJ4yIqVtgo~~5IWL9w6bsMgxhty-Mum86PsEpwVwr~DLXqxAHtxqO0KbQiomw7HGQgsRKT-GYkrsFVbIdY0tdUMU96TLygOJsTMbk2sj16PKmwBrCh50bd1Q5NMAHBl-2EFQ3CFxlx3~CB0mmOk09jFjcPCX0BieaigIpFjjjjbb7wUQ0dvZKUiqMgIJwYhFbFQFyux8qKopb0BX~CwhfUZlKEw2WDAf7mRLZ5frDBvhLY0a04JyYy3eis-DJXpgDhk1Cx04eGA__",
    lastMessage: "Thanks for your help yesterday...",
  },
]

const messages = {
  1: [
    // Group chat messages
    {
      id: 1,
      text: "Hi, Bessie 👋 I'd be glad to help you with optimizing your code for better performance. To get started, could you provide me with some more details about the specific challenges you're facing?",
      timestamp: "12:45 PM",
      sender: "AI Assistant",
      avatar: "https://hebbkx1anhila5yf.public.blob.vercel-storage.com/image-Wtx6NMXYLuhInX1qkbisDlMs8go4oY.png",
    },
    {
      id: 2,
      text: "Hi! I'm facing some challenges with my React application. It's becoming slow as I add more components and data. I'm not sure how to optimize it effectively.",
      timestamp: "12:47 PM",
      sender: "Bessie Cooper",
      avatar: "https://hebbkx1anhila5yf.public.blob.vercel-storage.com/image-Wtx6NMXYLuhInX1qkbisDlMs8go4oY.png",
    },
  ],
  2: [
    // Individual chat messages
    {
      id: 1,
      text: "Hi, Bessie 👋 I'd be glad to help you with optimizing your code for better performance. To get started, could you provide me with some more details about the specific challenges you're facing?",
      timestamp: "12:45 PM",
      sender: "AI Assistant",
      
    },
    {
      id: 2,
      text: "Hi! I'm facing some challenges with my React application. It's becoming slow as I add more components and data. I'm not sure how to optimize it effectively.",
      timestamp: "12:47 PM",
      sender: "Bessie Cooper",
      
    },
    {
      id: 3,
      text: "I see. There are several ways we can optimize a React application. Let's start with a few common techniques:\n\n1. Use React.memo for components that render often but don't always need to update.\n2. Implement lazy loading for components and routes.\n3. Optimize state management, possibly using libraries like Redux or Recoil for complex state.\n4. Use the useCallback hook to memoize functions.\n5. Employ useMemo for expensive computations.\n\nCan you tell me more about which parts of your app seem to be the slowest? Are there any specific actions that cause noticeable lag?",
      timestamp: "12:50 PM",
      sender: "AI Assistant",
     
    },
  ],
}

export default function ChatPage() {
  const [activeChat, setActiveChat] = useState(null)
  const [messageInput, setMessageInput] = useState("")
  const messagesEndRef = useRef(null)

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" })
  }

  useEffect(() => {
    scrollToBottom()
  }, [activeChat, messageInput]) // Added messageInput to dependencies

  const handleChatClick = (contact) => {
    if (activeChat && activeChat.id === contact.id) {
      setActiveChat(null)
    } else {
      setActiveChat(contact)
    }
  }

  const handleCloseChat = () => {
    setActiveChat(null)
  }

  return (
    <div>
      <div className="flex items-center justify-between pt-8 pb-4 px-16 mb-6">
        <div>
        <p className="text-2xl font-bold">Messages</p>
        </div>
        
        
          <div className="relative">
            <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
            <input
              type="search"
              placeholder="Search"
              className="w-[400px] pl-9 rounded-full border border-input bg-background px-3 py-2"
            />
          </div>
          <div className='flex gap-4'> 
          <Button size="icon" variant="ghost" className="relative">
            <Bell className="h-5 w-5" />
            <span className="absolute -right-1 -top-0.5 h-4 w-4 rounded-full bg-red-500 text-[10px] font-medium text-white flex items-center justify-center">
              1
            </span>
          </Button>
          <Button size="icon" variant="ghost" className="relative">
            <img src="./msg.png" className="h-8 w-8" />
            
          </Button>
          </div>
        </div>
      
   
    <div className="flex h-[832px] w-[995px] mx-auto rounded-3xl   border overflow-hidden">
    <div className="w-80 bg-white border-r flex flex-col h-full">
      <div className="py-6 px-8">
        <h1 className="font-semibold text-lg">My Inbox</h1>
      </div>
      <ScrollArea className="flex-grow">
        {contacts.map((contact) => (
          <div
            key={contact.id}
            className={`py-4 px-8 hover:bg-gray-50 cursor-pointer border-b ${activeChat && activeChat.id === contact.id ? "bg-gray-100" : ""}`}
            onClick={() => handleChatClick(contact)}
          >
            <div className="flex items-center gap-3">
              <div className="relative">
                {contact.type === "group" ? (
                  <Avatar>
                    <AvatarImage src={contact.avatar} />
                    <AvatarFallback>GC</AvatarFallback>
                  </Avatar>
                ) : (
                  <div className="relative">
                    <Avatar>
                      <AvatarImage src={contact.avatar} />
                      <AvatarFallback>
                        {contact.name
                          .split(" ")
                          .map((n) => n[0])
                          .join("")}
                      </AvatarFallback>
                    </Avatar>
                    <div
                      className={`absolute bottom-0 right-0 w-3 h-3 rounded-full border-2 border-white ${statusColors[contact.status]}`}
                    />
                  </div>
                )}
              </div>
              <div className="flex-1 min-w-0">
                <div className="font-medium">{contact.name}</div>
                <div className="text-sm text-gray-500 truncate">{contact.lastMessage}</div>
              </div>
            </div>
          </div>
        ))}
      </ScrollArea>

      <div className="p-2.5 border-t mt-auto w-full flex items-center justify-center gap-2 bg-white text-gray-600">
        <img src="./pen.png" className="h-5 w-5" alt="New Message" />
        New Message
      </div>
    </div>

    <div className="flex-1 flex flex-col">
      {activeChat ? (
        <>
          <div className="py-3 px-6 border-b bg-white sticky top-0 z-10">
            {activeChat.type === "group" ? (
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <Avatar>
                    <AvatarImage src={activeChat.avatar} />
                    <AvatarFallback>GC</AvatarFallback>
                  </Avatar>
                  <div>
                    <div className="font-medium">{activeChat.name}</div>
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  <div className="flex gap-1">
                    <img src="./addd.png" className="h-4 w-4 mt-1" alt="Invite" />
                    <span className="text-gray-500">Invite</span>
                  </div>
                  <div className="flex items-center gap-2 mt-1">
                    <AvatarGroup>
                      {activeChat.members.map((member) => (
                        <Avatar key={member.id} className="h-6 w-6">
                          <AvatarImage src={member.avatar} />
                          <AvatarFallback>
                            {member.name
                              .split(" ")
                              .map((n) => n[0])
                              .join("")}
                          </AvatarFallback>
                        </Avatar>
                      ))}
                    </AvatarGroup>
                  </div>
                  <Button variant="ghost" size="icon">
                    <img src="./Menu.png" className="h-4 w-4" alt="Menu" />
                  </Button>
                </div>
              </div>
            ) : (
              <div className="flex justify-between items-center">
                <div className="flex items-center gap-3">
                  <div className="relative">
                    <Avatar>
                      <AvatarImage src={activeChat.avatar} />
                      <AvatarFallback>
                        {activeChat.name
                          .split(" ")
                          .map((n) => n[0])
                          .join("")}
                      </AvatarFallback>
                    </Avatar>
                    <div
                      className={`absolute bottom-0 right-0 w-3 h-3 rounded-full border-2 border-white ${statusColors[activeChat.status]}`}
                    />
                  </div>
                  <div>
                    <div className="font-medium">{activeChat.name}</div>
                  </div>
                </div>
                <Button variant="ghost" size="icon">
                  <img src="./Menu.png" className="h-4 w-4" alt="Menu" />
                </Button>
              </div>
            )}
          </div>

          <ScrollArea className="flex-1 py-6 px-12 pt-24 pb-20">
            <div className="space-y-6">
              <div className="flex items-center my-6">
                <div className="flex-grow border-t border-gray-300 border-2"></div>
                <span className="text-sm text-gray-500">18 January 2025</span>
                <div className="flex-grow border-t border-gray-300 border-2"></div>
              </div>

              {(messages[activeChat.id] || []).map((message) => (
                <div
                  key={message.id}
                  className={`flex gap-3 ${message.sender === "AI Assistant" ? "justify-end" : ""}`}
                >
                  <div className={`flex-1 ${message.sender === "AI Assistant" ? "text-right" : ""}`}>
                    <div
                      className={`rounded-lg p-3 w-fit max-w-[60%] whitespace-pre-wrap ${
                        message.sender === "AI Assistant"
                          ? "bg-[#4C68D5] text-white ml-auto"
                          : "bg-[#F1F4F9] text-[#27364B]"
                      }`}
                    >
                      {message.text}
                      <div className="text-sm text-end">{message.timestamp}</div>
                    </div>
                  </div>
                </div>
              ))}
              <div ref={messagesEndRef} />
            </div>
          </ScrollArea>

          <div className="flex p-2">
            <div className="mt-8">
              <Avatar>
                <AvatarImage src={activeChat.avatar} />
                <AvatarFallback></AvatarFallback>
              </Avatar>
            </div>

            <div className="flex items-center border-[#ABB0B9] rounded-full border px-2 py-2 m-6 w-full">
              <label className="cursor-pointer flex items-center">
                <img src="./Paper.png" className="w-5 h-5" alt="Attach file" />
                <input type="file" accept="image/*" className="hidden" />
              </label>

              <input placeholder="Type a message..." className="flex-1 px-4 py-2 outline-none text-sm" />

              <button className="text-blue-500 p-2 rounded-full hover:bg-blue-100">
                <img src="./Plain.png" className="w-5 h-5" alt="Send" />
              </button>
            </div>
          </div>
        </>
      ) : (
        <MessagePlaceholder />
      )}
    </div>
  </div>
  </div>
  )
}

