﻿namespace $rootnamespace$.FluentACSSamples
{
    using System;
    using System.Diagnostics;
    using System.IO;
    using System.Security.Cryptography.X509Certificates;

    using FluentACS;

    public class Samples
    {
        private readonly AcsNamespaceDescription namespaceDesc = new AcsNamespaceDescription("acsNamespace", "acsUserName", "acsPassword");

        public void AddGoogleAndYahooIdentityProviders()
        {
            var acsNamespace = new AcsNamespace(this.namespaceDesc);
            acsNamespace
                .AddGoogleIdentityProvider()
                .AddYahooIdentityProvider();

            acsNamespace.SaveChanges(logInfo => Trace.WriteLine(logInfo.Message));
        }

        public void AddVandelayIndustriesServiceIdentity()
        {
            var acsNamespace = new AcsNamespace(this.namespaceDesc);
            acsNamespace.AddServiceIdentity(
                si => si
                    .Name("Vandelay Industries")
                    .Password("Passw0rd!"));

            acsNamespace.SaveChanges(logInfo => Trace.WriteLine(logInfo.Message));
        }

        public void AddMyCoolWebsiteRelyingPartyWithSwtTokenDetails()
        {
            var acsNamespace = new AcsNamespace(this.namespaceDesc);
            acsNamespace.AddRelyingParty(
                rp => rp
                    .Name("MyCoolWebsite")
                    .RealmAddress("http://mycoolwebsite.com/")
                    .ReplyAddress("http://mycoolwebsite.com/")
                    .AllowGoogleIdentityProvider()
                    .AllowWindowsLiveIdentityProvider()
                    .SwtToken()
                    .TokenLifetime(120)
                    .SymmetricKey(Convert.FromBase64String("yMryA5VQVmMwrtuiJBfyjMnAJwoT7//fCuM6NwaHjQ1=")));

            acsNamespace.SaveChanges(logInfo => Trace.WriteLine(logInfo.Message));
        }

        public void AddMyCoolWebsiteRelyingPartyWithSamlTokenDetails()
        {
            var encryptionCert = new X509Certificate(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "testCert.cer"));
            var signingCertBytes = this.ReadBytesFromPfxFile(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "testCert_xyz.pfx"));
            var temp = new X509Certificate2(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "testCert_xyz.pfx"), "xyz");
            var startDate = temp.NotBefore.ToUniversalTime();
            var endDate = temp.NotAfter.ToUniversalTime();

            var acsNamespace = new AcsNamespace(this.namespaceDesc);
            acsNamespace.AddRelyingParty(
                rp => rp
                    .Name("MyCoolWebsite")
                    .RealmAddress("http://mycoolwebsite.com/")
                    .ReplyAddress("http://mycoolwebsite.com/")
                    .AllowGoogleIdentityProvider()
                    .AllowWindowsLiveIdentityProvider()
                    .SamlToken()
                    .TokenLifetime(120)
                    .SigningCertificate(sc => sc.Bytes(signingCertBytes).Password("xyz").StartDate(startDate).EndDate(endDate)) 
                    .EncryptionCertificate(encryptionCert.GetRawCertData()));

            acsNamespace.SaveChanges(logInfo => Trace.WriteLine(logInfo.Message));
        }

        public void AddMyCoolWebsiteRelyingPartyWithRuleGroupAndRules()
        {
            var acsNamespace = new AcsNamespace(this.namespaceDesc);
            
            const string MyCoolWebsite = "MyCoolWebsite";
            const string RuleGroupForMyCoolWebsiteRelyingParty = "Rule Group for MyCoolWebsite Relying Party";

            acsNamespace.AddRelyingParty(
                rp => rp
                    .Name(MyCoolWebsite)
                    .RealmAddress("http://mycoolwebsite.com/")
                    .ReplyAddress("http://mycoolwebsite.com/")
                    .AllowGoogleIdentityProvider()
                    .AllowYahooIdentityProvider()
                    .AllowWindowsLiveIdentityProvider()
                    .RemoveRelatedRuleGroups()
                    .AddRuleGroup(rg => rg
                                .Name(RuleGroupForMyCoolWebsiteRelyingParty)
                                .AddRule(
                                    rule => rule
                                        .Description("Google Passthrough")
                                        .IfInputClaimIssuer().Is("Google")
                                        .AndInputClaimType().IsOfType("http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress")
                                        .AndInputClaimValue().IsAny()
                                        .ThenOutputClaimType().ShouldBe("http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name")
                                        .AndOutputClaimValue().ShouldPassthroughFirstInputClaimValue())
                                .AddRule(
                                    rule => rule
                                        .Description("Yahoo! Passthrough")
                                        .IfInputClaimIssuer().Is("Yahoo!")
                                        .AndInputClaimType().IsAny()
                                        .AndInputClaimValue().IsAny()
                                        .ThenOutputClaimType().ShouldPassthroughFirstInputClaimType()
                                        .AndOutputClaimValue().ShouldPassthroughFirstInputClaimValue())
                                .AddRule(
                                    rule => rule
                                        .Description("Windows Live ID rule")
                                        .IfInputClaimIssuer().Is("Windows Live ID")
                                        .AndInputClaimType().IsOfType("http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress")
                                        .AndInputClaimValue().Is("johndoe@hotmail.com")
                                        .ThenOutputClaimType().ShouldBe("http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier")
                                        .AndOutputClaimValue().ShouldBe("John Doe"))
                                .AddRule(
                                    rule => rule
                                        .Description("ACS rule")
                                        .IfInputClaimIssuer().IsAcs()
                                        .AndInputClaimType().IsAny()
                                        .AndInputClaimValue().IsAny()
                                        .ThenOutputClaimType().ShouldPassthroughFirstInputClaimType()
                                        .AndOutputClaimValue().ShouldPassthroughFirstInputClaimValue())));

            acsNamespace.SaveChanges(logInfo => Trace.WriteLine(logInfo.Message));
        }

        public byte[] ReadBytesFromPfxFile(string pfxFileName)
        {
            byte[] signingCertificate;
            using (var stream = File.OpenRead(pfxFileName))
            {
                using (var br = new BinaryReader(stream))
                {
                    signingCertificate = br.ReadBytes((int)stream.Length);
                }
            }

            return signingCertificate;
        }
    }
}
