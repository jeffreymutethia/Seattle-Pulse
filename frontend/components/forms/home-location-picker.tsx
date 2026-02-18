"use client"

import { useMemo } from "react"
import AsyncSelect from "react-select/async"
import type { GroupBase, OptionsOrGroups } from "react-select"
import { useHomeLocationSearch } from "@/app/hooks/use-location-search"

export type HomeLocationValue = string

interface HomeLocationOption {
  value: string
  label: string
  isPreset?: boolean
  city?: string
}

interface HomeLocationPickerProps {
  value: HomeLocationValue
  onChange: (value: HomeLocationValue) => void
  placeholder?: string
  inputId?: string
  className?: string
}

const controlBorderColor = "#ABB0B9"

const HomeLocationPicker = ({
  value,
  onChange,
  placeholder = "Choose a neighborhood...",
  inputId,
  className,
}: HomeLocationPickerProps) => {
  const { loadOptions, isLoading, launchSet } = useHomeLocationSearch()

  const selectedOption = useMemo<HomeLocationOption | null>(() => {
    if (!value) return null
    return { value, label: value }
  }, [value])

  const handleChange = (option: HomeLocationOption | null) => {
    onChange(option?.value ?? "")
  }

  return (
    <AsyncSelect<HomeLocationOption, false>
      inputId={inputId}
      instanceId={inputId}
      value={selectedOption}
      loadOptions={loadOptions as (
        inputValue: string,
        callback: (options: OptionsOrGroups<HomeLocationOption, GroupBase<HomeLocationOption>>) => void,
      ) => void}
      defaultOptions={launchSet}
      onChange={handleChange}
      placeholder={placeholder}
      className={className ?? "w-full"}
      classNamePrefix="home-location"
      isClearable
      isLoading={isLoading}
      loadingMessage={() => "Searching neighborhoods..."}
      noOptionsMessage={() => "No neighborhoods found"}
      cacheOptions={false}
      styles={{
        control: (base, state) => ({
          ...base,
          borderRadius: 9999,
          minHeight: 48,
          borderColor: state.isFocused ? "#111827" : controlBorderColor,
          boxShadow: "none",
          '&:hover': {
            borderColor: state.isFocused ? "#111827" : controlBorderColor,
          },
        }),
        menu: (base) => ({
          ...base,
          borderRadius: 12,
          overflow: "hidden",
          zIndex: 30,
        }),
        option: (base, state) => ({
          ...base,
          backgroundColor: state.isSelected ? "#111827" : state.isFocused ? "#F1F5F9" : base.backgroundColor,
          color: state.isSelected ? "#FFFFFF" : base.color,
        }),
        valueContainer: (base) => ({
          ...base,
          paddingLeft: 16,
        }),
        placeholder: (base) => ({
          ...base,
          color: "#677080",
        }),
      }}
      theme={(theme) => ({
        ...theme,
        colors: {
          ...theme.colors,
          primary25: "#F1F5F9",
          primary: "#111827",
        },
      })}
    />
  )
}

export default HomeLocationPicker
