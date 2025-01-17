#!/usr/bin/env bash

get_tmux_option() {
	local option=$1
	local default_value=$2
	local option_value=$(tmux show-option -gqv "$option")
	if [ -z $option_value ]; then
		echo $default_value
	else
		echo $option_value
	fi
}

update_status() {
	local placeholder
	local status_value

	placeholder="\#{wttr}"
		status_value="$(get_tmux_option "$1")"

	tmux set-option -gq "$1" "${status_value/$placeholder/$2}"
}

get_weather() {
	local format

	#format=$(get_tmux_option "@wttr_format" "%C+%t")
	format=$(get_tmux_option "@wttr_format" "%C+%t+%o+%w+%h+%m")

	#curl -s "https://wttr.in/?format=$format" | sed -e 's/°F/°/' -e 's/+//' -e 's/\s+$//' | tr '[:upper:]' '[:lower:]'
	curl -s "https://wttr.in/?format=$format"
}

get_weather_from_cache() {
	local cache_file
	local cache_ttl
	local current_dir
	local now
	local mod

	current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
	cache_file="$current_dir/cache"
	cache_ttl=$(get_tmux_option "@wttr_cache_ttl" 900)

	if [[ -f "$cache_file" ]]; then
		now=$(date +%s)
		mod=$(date -r "$cache_file" +%s)
		if [[ $(( now - mod )) -gt $cache_ttl ]]; then
			rm "$cache_file"
		fi
	fi

	if [[ ! -f "$cache_file" ]]; then
		get_weather > "$cache_file"
	fi

	cat "$cache_file"
}

main()
{
	# set current directory variable
	current_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

  # set configuration option variables
  show_battery=$(get_tmux_option "@dracula-show-battery" true)
  show_network=$(get_tmux_option "@dracula-show-network" true)
  show_weather=$(get_tmux_option "@dracula-show-weather" true)
  show_powerline=$(get_tmux_option "@dracula-show-powerline" flse)
  show_left_icon=$(get_tmux_option "@dracula-show-left-icon" smiley)
  show_military=$(get_tmux_option "@dracula-military-time" false)
  show_left_sep=$(get_tmux_option "@dracula-show-left-sep" )
  show_right_sep=$(get_tmux_option "@dracula-show-right-sep" )
  show_border_contrast=$(get_tmux_option "@dracula-border-contrast" false)
  show_cpu_usage=$(get_tmux_option "@dracula-cpu-usage" true)
  show_ram_usage=$(get_tmux_option "@dracula-ram-usage" true)

  # Dracula Color Pallette
  white='#f8f8f2'
  gray='#44475a'
  dark_gray='#282a36'
  light_purple='#bd93f9'
  dark_purple='#6272a4'
  cyan='#8be9fd'
  green='#50fa7b'
  orange='#ffb86c'
  red='#ff5555'
  pink='#ff79c6'
  yellow='#f1fa8c'


  # Handle left icon configuration
  case $show_left_icon in
	  smiley)
		  left_icon="☺ ";;
	  session)
		  left_icon="#S ";;
	  window)
		  left_icon="#W ";;
	  *)
		  left_icon=$show_left_icon;;
  esac

  # Handle powerline option
  if $show_powerline; then
	  right_sep="$show_right_sep"
	  left_sep="$show_left_sep"
  fi

  # sets refresh interval to every 5 seconds
  tmux set-option -g status-interval 5

  # set clock to 12 hour by default
  tmux set-option -g clock-mode-style 12

  # set length
  tmux set-option -g status-left-length 100
  tmux set-option -g status-right-length 200

  # pane border styling
  if $show_border_contrast; then
	  tmux set-option -g pane-active-border-style "fg=${light_purple}"
  else
	  tmux set-option -g pane-active-border-style "fg=${dark_purple}"
  fi
  tmux set-option -g pane-border-style "fg=${gray}"

  # message styling
  tmux set-option -g message-style "bg=${gray},fg=${white}"

  # status bar
  tmux set-option -g status-style "bg=${gray},fg=${white}"

  output="$(get_weather_from_cache)"

  # Powerline Configuration
  if $show_powerline; then

	  tmux set-option -g status-left "#[bg=${green},fg=${dark_gray}]#{?client_prefix,#[bg=${yellow}],} ${left_icon} #[fg=${green},bg=${gray}]#{?client_prefix,#[fg=${yellow}],}${left_sep}"
	  tmux set-option -g  status-right ""
	  powerbg=${gray}

	  if $show_battery; then # battery
		  tmux set-option -g  status-right "#[fg=${pink},bg=${powerbg},nobold,nounderscore,noitalics] ${right_sep}#[fg=${dark_gray},bg=${pink}] #($current_dir/battery.sh)"
		  powerbg=${pink}
	  fi

	  if $show_ram_usage; then
		  tmux set-option -ga status-right "#[fg=${cyan},bg=${powerbg},nobold,nounderscore,noitalics] ${right_sep}#[fg=${dark_gray},bg=${cyan}] #($current_dir/ram_info.sh)"
		  powerbg=${cyan}
	  fi

	  if $show_cpu_usage; then
		  tmux set-option -ga status-right "#[fg=${orange},bg=${powerbg},nobold,nounderscore,noitalics] ${right_sep}#[fg=${dark_gray},bg=${orange}] #($current_dir/cpu_info.sh)"
		  powerbg=${orange}
	  fi

	  if $show_network; then # network
		  tmux set-option -ga status-right "#[fg=${cyan},bg=${powerbg},nobold,nounderscore,noitalics] ${right_sep}#[fg=${dark_gray},bg=${cyan}] #($current_dir/network.sh)"
		  powerbg=${cyan}
	  fi

	  if $show_weather; then # weather
		  tmux set-option -ga status-right "#[fg=${orange},bg=${powerbg},nobold,nounderscore,noitalics] ${right_sep}#[fg=${dark_gray},bg=${orange}] #{wttr} "
		  powerbg=${orange}
	  fi

	  if $show_military; then # military time
		  tmux set-option -ga status-right "#[fg=${dark_purple},bg=${powerbg},nobold,nounderscore,noitalics] ${right_sep}#[fg=${white},bg=${dark_purple}] %a %m/%d %R #(date +%Z) "
	  else
		  tmux set-option -ga status-right "#[fg=${dark_purple},bg=${powerbg},nobold,nounderscore,noitalics] ${right_sep}#[fg=${white},bg=${dark_purple}] %a %m/%d %I:%M %p #(date +%Z) "
	  fi

	  tmux set-window-option -g window-status-current-format "#[fg=${gray},bg=${dark_purple}]${left_sep}#[fg=${white},bg=${dark_purple}] #I #W #[fg=${dark_purple},bg=${gray}]${left_sep}"

  # Non Powerline Configuration
else
	tmux set-option -g status-left "#[bg=${green},fg=${dark_gray}]#{?client_prefix,#[bg=${yellow}],} ${left_icon}"

	tmux set-option -g  status-right ""

	if $show_battery; then # battery
		tmux set-option -g  status-right "#[fg=${dark_gray},bg=${pink}] #($current_dir/battery.sh) "
	fi
	if $show_ram_usage; then
		tmux set-option -ga status-right "#[fg=${dark_gray},bg=${cyan}] #($current_dir/ram_info.sh) "
	fi

	if $show_cpu_usage; then
		tmux set-option -ga status-right "#[fg=${dark_gray},bg=${orange}] #($current_dir/cpu_info.sh) "
	fi

	if $show_network; then # network
		tmux set-option -ga status-right "#[fg=${dark_gray},bg=${cyan}] #($current_dir/network.sh) "
	fi

	if $show_weather; then # weather
		tmux set-option -ga status-right "#[fg=${dark_gray},bg=${orange}] #{wttr} "
	fi

	if $show_military; then # military time
		tmux set-option -ga status-right "#[fg=${white},bg=${dark_purple}] %a %m/%d %R #(date +%Z) "
	else
		tmux set-option -ga status-right "#[fg=${white},bg=${dark_purple}] %a %m/%d %I:%M %p #(date +%Z) "
	fi

	tmux set-window-option -g window-status-current-format "#[fg=${white},bg=${dark_purple}] #I #W "

  fi

  tmux set-window-option -g window-status-format "#[fg=${white}]#[bg=${gray}] #I #W "
  update_status "status-left" "$output"
  update_status "status-right" "$output"
}

# run main function
main
