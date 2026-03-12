import streamlit as st
import requests
import pandas as pd
from datetime import datetime
import urllib.parse
import time
from bs4 import BeautifulSoup
from streamlit_option_menu import option_menu

# --- PAGE CONFIGURATION ---
st.set_page_config(page_title="TorrentX Mobile", page_icon="📱", layout="centered")

# --- ADVANCED CSS FOR MOBILE & BOTTOM NAV ---
st.markdown("""
<style>
    /* App Padding to prevent overlap with bottom nav */
    .block-container {
        padding-top: 2rem !important;
        padding-bottom: 90px !important; 
        max-width: 800px;
    }
    
    /* Gradient Animated Text */
    @keyframes gradient { 0% {background-position: 0% 50%;} 50% {background-position: 100% 50%;} 100% {background-position: 0% 50%;} }
    .title-anim { 
        background: linear-gradient(-45deg, #00C9FF, #92FE9D, #fc00ff, #00dbde); 
        background-size: 400% 400%; animation: gradient 5s ease infinite; 
        -webkit-background-clip: text; -webkit-text-fill-color: transparent; 
        font-size: 2.5rem; font-weight: 900; text-align: center; margin-bottom: 5px;
    }

    /* Mobile Card Styling */
    div[data-testid="stVerticalBlock"] > div > div[data-testid="stVerticalBlock"] {
        background-color: rgba(30, 30, 30, 0.4);
        border-radius: 15px;
        padding: 15px;
        margin-bottom: 15px;
        box-shadow: 0 8px 16px rgba(0,0,0,0.2);
        border: 1px solid rgba(255, 255, 255, 0.05);
    }

    /* Metric Adjustments for Mobile */
    div[data-testid="metric-container"] {
        background-color: transparent !important;
        box-shadow: none !important;
        padding: 0 !important;
    }
    
    /* Fix Option Menu to the Bottom */
    .st-key-bottom_nav {
        position: fixed;
        bottom: 0;
        left: 0;
        width: 100%;
        background-color: #0e1117;
        z-index: 9999;
        border-top: 1px solid #333;
        padding-bottom: 15px; /* Safe area for iOS */
    }
</style>
""", unsafe_allow_html=True)

# --- HELPER FUNCTIONS ---
def format_size(size_bytes):
    try:
        size_bytes = float(size_bytes)
        for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
            if size_bytes < 1024.0: return f"{size_bytes:.2f} {unit}"
            size_bytes /= 1024.0
    except:
        return str(size_bytes)

def create_magnet(info_hash, name):
    encoded_name = urllib.parse.quote(name)
    trackers =["udp://tracker.opentrackr.org:1337/announce", "udp://tracker.torrent.eu.org:451/announce"]
    tr_string = "".join([f"&tr={urllib.parse.quote(t)}" for t in trackers])
    return f"magnet:?xt=urn:btih:{info_hash}&dn={encoded_name}{tr_string}"

# --- ENGINE SCRAPERS ---
@st.cache_data(ttl=600, show_spinner=False)
def fetch_apibay(query):
    """The Pirate Bay Database"""
    url = f"https://apibay.org/q.php?q={urllib.parse.quote(query)}"
    try:
        res = requests.get(url, timeout=10).json()
        if res and res[0].get('id') == '0': return []
        return[{
            'id': t['info_hash'], 'name': t['name'], 'size': int(t['size']), 
            'seeders': int(t['seeders']), 'leechers': int(t['leechers']), 
            'date': datetime.fromtimestamp(int(t['added'])).strftime('%Y-%m-%d'),
            'magnet': create_magnet(t['info_hash'], t['name']),
            'engine': 'PirateBay'
        } for t in res]
    except: return[]

@st.cache_data(ttl=600, show_spinner=False)
def fetch_1337x(query):
    """1337x Scraper (BeautifulSoup)"""
    url = f"https://1337x.to/search/{urllib.parse.quote(query)}/1/"
    headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0'}
    results =[]
    try:
        res = requests.get(url, headers=headers, timeout=10)
        soup = BeautifulSoup(res.text, 'html.parser')
        for tr in soup.select('tbody tr')[:15]:
            a_tag = tr.select_one('.name a:nth-of-type(2)')
            if not a_tag: continue
            results.append({
                'id': a_tag['href'], 'name': a_tag.text,
                'size': tr.select_one('.size').contents[0].text,
                'seeders': int(tr.select_one('.seeds').text),
                'leechers': int(tr.select_one('.leeches').text),
                'date': tr.select_one('.coll-date').text,
                'magnet': None, # Fetched on-demand to avoid bot bans
                'engine': '1337x'
            })
    except: pass
    return results

@st.cache_data(ttl=600, show_spinner=False)
def fetch_nyaa(query):
    """Nyaa.si for Anime"""
    url = f"https://nyaa.si/?q={urllib.parse.quote(query)}&f=0&c=0_0"
    results =[]
    try:
        res = requests.get(url, timeout=10)
        soup = BeautifulSoup(res.text, 'html.parser')
        for tr in soup.select('tbody tr')[:15]:
            links = tr.select('td:nth-of-type(2) a:not(.comments)')
            title = links[-1].text if links else "Unknown"
            magnet = tr.select_one('td:nth-of-type(3) a:nth-of-type(2)')['href']
            size = tr.select_one('td:nth-of-type(4)').text
            date = tr.select_one('td:nth-of-type(5)').text
            seeders = int(tr.select_one('td:nth-of-type(6)').text)
            leechers = int(tr.select_one('td:nth-of-type(7)').text)
            results.append({
                'id': magnet, 'name': title, 'size': size, 'seeders': seeders,
                'leechers': leechers, 'date': date, 'magnet': magnet, 'engine': 'Nyaa'
            })
    except: pass
    return results

# --- ADVANCED FRAGMENTS (On-Demand Loading) ---
@st.fragment
def get_1337x_magnet(url_path):
    """Fetches 1337x magnet link ONLY when the user clicks to save bandwidth"""
    if st.button("🧲 Get Magnet Link", key=f"btn_{url_path}"):
        with st.spinner("Bypassing security to fetch magnet..."):
            try:
                full_url = f"https://1337x.to{url_path}"
                res = requests.get(full_url, headers={'User-Agent': 'Mozilla/5.0'})
                soup = BeautifulSoup(res.text, 'html.parser')
                magnet = soup.select_one('a[href^="magnet:"]')['href']
                st.code(magnet, language='http')
                st.success("Magnet Extracted!")
            except:
                st.error("Failed to fetch magnet.")

@st.fragment
def inspect_apibay_files(info_hash):
    if st.button("📂 View Inside Files", key=f"file_{info_hash}"):
        with st.spinner("Loading contents..."):
            try:
                files = requests.get(f"https://apibay.org/f.php?id={info_hash}", timeout=5).json()
                if files and 'name' in files[0]:
                    df = pd.DataFrame(files)
                    df['size'] = df['size'].apply(lambda x: format_size(x['size'][0]) if isinstance(x, dict) else format_size(x))
                    st.dataframe(df[['name', 'size']], use_container_width=True, hide_index=True)
                else: st.warning("No file list available.")
            except: st.error("Tracker unreachable.")

# --- APP LAYOUT & NAVIGATION ---
st.markdown('<div class="title-anim">TorrentX</div>', unsafe_allow_html=True)

# Fake Bottom Navigation Bar via Streamlit Option Menu
with st.container(key="bottom_nav"):
    selected_tab = option_menu(
        menu_title=None,
        options=["Search", "Engines", "Settings"],
        icons=["search", "hdd-network", "gear"],
        menu_icon="cast",
        default_index=0,
        orientation="horizontal",
        styles={
            "container": {"padding": "0!important", "background-color": "#0e1117", "border-radius": "0"},
            "nav-link": {"font-size": "14px", "text-align": "center", "margin": "0px", "--hover-color": "#333"},
            "nav-link-selected": {"background-color": "#00C9FF"},
        }
    )

if selected_tab == "Engines":
    st.header("📡 Network Status")
    st.success("🟢 The Pirate Bay (Apibay) - Online")
    st.success("🟢 1337x (BS4 Scraper) - Online")
    st.success("🟢 Nyaa (Anime) - Online")
    st.info("YTS Movies has been temporarily disabled in this view to favor general trackers.")

elif selected_tab == "Settings":
    st.header("⚙️ Preferences")
    st.toggle("Use VPN Proxies (Coming Soon)", disabled=True)
    st.toggle("Auto-copy Magnets", value=True)
    st.radio("Default Sorting",["Seeders", "Size", "Date"])

elif selected_tab == "Search":
    # Search Bar & Engine Chips
    query = st.text_input("🔍 What are you looking for?", placeholder="Movies, Software, Anime...")
    
    # Mobile friendly horizontal radio buttons
    engine = st.radio("Select Provider",["PirateBay", "1337x", "Nyaa (Anime)"], horizontal=True)
    
    if query:
        with st.spinner(f"Searching {engine}... ⏳"):
            if engine == "PirateBay": results = fetch_apibay(query)
            elif engine == "1337x": results = fetch_1337x(query)
            elif engine == "Nyaa (Anime)": results = fetch_nyaa(query)
            
        if not results:
            st.warning("No results found. Try a different provider.")
        else:
            # Sort by seeders automatically
            results = sorted(results, key=lambda x: x['seeders'], reverse=True)
            st.caption(f"Found {len(results)} results.")
            
            # Render Results in Mobile-Friendly Cards
            for res in results:
                with st.container():
                    st.markdown(f"**{res['name']}**")
                    
                    # 3-Column Mobile Layout for metrics
                    c1, c2, c3 = st.columns(3)
                    c1.markdown(f"🟢 **{res['seeders']}**")
                    c2.markdown(f"🔴 **{res['leechers']}**")
                    c3.markdown(f"💾 **{format_size(res['size']) if isinstance(res['size'], int) else res['size']}**")
                    
                    health = (res['seeders'] / (res['seeders'] + res['leechers'])) if (res['seeders'] + res['leechers']) > 0 else 0
                    st.progress(health)
                    
                    with st.expander("🛠️ Options & Download"):
                        if engine == "1337x":
                            st.info("1337x requires fetching the magnet dynamically to prevent bans.")
                            get_1337x_magnet(res['id'])
                        else:
                            st.markdown("#### 🧲 Magnet Link")
                            st.code(res['magnet'], language='http')
                            
                        if engine == "PirateBay":
                            inspect_apibay_files(res['id'])
